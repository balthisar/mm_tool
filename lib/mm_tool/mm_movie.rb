module MmTool

  #=============================================================================
  # A movie as a self contained class. Instances of this class consist of
  # one or more MmMovieStream instances, and contains intelligence about itself
  # so that it can provide commands to ffmpeg and/or mkvpropedit as required.
  # Upon creation it must be provided with a filename and an options hash.
  #=============================================================================
  class MmMovie

    require 'mm_tool/mm_movie_stream'
    require 'streamio-ffmpeg'
    require 'tty-screen'
    require 'tty-table'
    require 'pastel'
    require 'bytesize'

    #------------------------------------------------------------
    # This class method returns the known dispositions supported
    # by ffmpeg. This array also reflects the output orders in
    # the dispositions table field. Not combining them would
    # result in a too-long table row.
    #------------------------------------------------------------
    def self.dispositions
      %i(default dub original comment lyrics karaoke forced hearing_impaired visual_impaired clean_effects attached_pic timed_thumbnails)
    end

    #------------------------------------------------------------
    # Attributes
    #------------------------------------------------------------
    attr_reader :ff_movie            # Exposed instance of the FFMPEG::Movie
    attr_reader :path                # Path to the on-disk file this instance represents.
    attr_reader :table               # A TTY:Table consisting of each streams' information.
    attr_reader :table_text
    attr_reader :table_text_plain

    #------------------------------------------------------------
    # Define and setup module level variables.
    #------------------------------------------------------------
    def initialize(with_file:, options:)
      @c = Pastel.new(enabled: $stdout.tty? && $stderr.tty?)

      @path = with_file
      @options = options

      @ff_movie = FFMPEG::Movie.new(with_file)
      @streams = MmMovieStream::streams(from_movie: self)

      @table = build_table_for_movie
      @table_text = render_table(true)
      @table_text_plain = render_table(false)
    end


    #------------------------------------------------------------
    # Get the file-level 'title' metadata.
    #------------------------------------------------------------
    def format_title
      @ff_movie&.metadata&.dig(:format, :tags, :title)
    end

    #------------------------------------------------------------
    # Get the file-level 'duration' metadata.
    #------------------------------------------------------------
    def format_duration
      seconds = @ff_movie&.metadata&.dig(:format, :duration)
      seconds ? Time.at(seconds.to_i).utc.strftime("%H:%M:%S") : nil
    end

    #------------------------------------------------------------
    # Get the file-level 'size' metadata.
    #------------------------------------------------------------
    def format_size
      size = @ff_movie&.metadata&.dig(:format, :size)
      size ? ByteSize.new(size) : 'unknown'
    end


    private

    #------------------------------------------------------------
    # Return a TTY::Table of the movie, populated with the
    # pertinent data of each stream.
    #------------------------------------------------------------
    def build_table_for_movie

      # Ensure that when we add the headers, they specifically are left-aligned.
      headers = %w(index codec type w/# h/layout lang disposition title action(s))
                    .map { |header| {:value => header, :alignment => :left} }

      table = TTY::Table.new(header: headers)

      @ff_movie.metadata[:streams].each do |stream|
        w_col = stream[:coded_width]
        h_col = stream[:coded_height]

        if stream[:codec_type] == 'audio'
          w_col = stream[:channels]
          h_col = stream[:channel_layout]
        elsif stream[:codec_type] == 'subtitle'
          w_col = 'n/a'
          h_col = 'n/a'
        end

        if stream.key?(:tags)
          lang = stream[:tags][:language]
          lang = stream[:tags][:LANGUAGE] unless lang
          lang = @c.cyan('und') unless lang
          title = stream[:tags][:title]
        else
          lang = @c.cyan('und')
          title = ''
        end

        row = [stream[:index], stream[:codec_name], stream[:codec_type], w_col, h_col, lang]
        row << self.class.dispositions
                   .collect {|symbol| stream[:disposition][symbol]}
                   .join(',')
        row << title
        row << ''

        table << row
      end
      table
    end # build_table_for_movie

    #------------------------------------------------------------
    # For the given table, get the rendered text of the table
    # for output.
    #------------------------------------------------------------
    def render_table(colorize = true)
      columns = [5,10,10,5,10,5,23,30,15]
      table_min = columns.sum + columns.count * 2 + 2

      if table_min < TTY::Screen.width
        columns[7] = columns[7] + TTY::Screen.width - table_min - 8
      end

      unless colorize
        columns[7] = 80
      end

      @table.render(:unicode) do |renderer|
        renderer.alignments    = [:center, :left, :left, :right, :right, :left, :left, :left, :center]
        renderer.column_widths = columns
        renderer.multiline     = true
        renderer.padding       = [0,1]
        renderer.width         = 1000
        if colorize
          renderer.border.style = :bright_black
          renderer.filter = -> (val, row, col) do
            if row == 0
              @c.italic(val)
            else
              val
            end
          end # do
        else
          renderer.filter = -> (val, row, col) { @c.strip(val) }
        end # if colorize
      end # do
    end

  end # class MmMovie

end # module MmTool
