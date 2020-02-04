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
    attr_reader :path                # Path to the on-disk file this instance represents.
    attr_writer :options             # Exposed options hash.
    attr_reader :ff_movie            # Exposed instance of the FFMPEG::Movie
    attr_reader :streams             # Exposed array of MmMovieStream.

    attr_reader :table_text
    attr_reader :table_text_plain

    #------------------------------------------------------------
    # Define and setup instance variables.
    #------------------------------------------------------------
    def initialize(with_file:, owner:)
      @c = Pastel.new(enabled: $stdout.tty? && $stderr.tty?)

      @path = with_file
      @owner = owner

      @ff_movie = FFMPEG::Movie.new(with_file)
      @streams = MmMovieStream::streams(from_movie: self)

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

    #------------------------------------------------------------
    # Return a TTY::Table of the movie, populated with the
    # pertinent data of each stream.
    #------------------------------------------------------------
    def table
      unless @table
        # Ensure that when we add the headers, they specifically are left-aligned.
        headers = %w(index codec type w/# h/layout lang disposition title action(s))
                      .map { |header| {:value => header, :alignment => :left} }

        @table = TTY::Table.new(header: headers)

        @streams.each do |stream|
          row = []
          row << stream.index
          row << stream.codec_name
          row << stream.codec_type
          row << stream.quality_01
          row << stream.quality_02
          row << stream.language
          row << stream.dispositions
          row << stream.title
          row << 'some action'
          @table << row
        end
      end
      @table
    end # table


    #------------------------------------------------------------
    # The name of the proposed output file, if different from
    # the input file. This would be set in the event that the
    # container of the input file is not one of the approved
    # containers.
    #------------------------------------------------------------
    def output_path
      if @owner[:containers_preferred].include?(File.extname(@path))
        @path
      else
        File.join(File.dirname(@path), File.basename(@path, '.*') + '.' + @owner[:containers_preferred][0])
      end
    end

    #------------------------------------------------------------
    # The proposed, new name of the input file, if transcoding
    # is to be performed. The transcoding script will rename
    # the source file to this name before transcoding.
    #------------------------------------------------------------
    def new_input_path
      File.join(File.dirname(@path), File.basename(@path, '.*') + @owner[:suffix] + File.extname(@path))
    end

    #------------------------------------------------------------
    # The complete, proposed ffmpeg command to transcode the
    # input file to an output file. It uses the 'new_input_path'
    # as the input file.
    #------------------------------------------------------------
    def command_transcode
      command = []
      command << "ffmpeg -i \"#{new_input_path}\" \\"
      process_streams_pass_1
      command << "   \"#{output_path}\""
    end

    private

    def process_streams_pass_1

      @streams.each do |stream|

        if stream.codec_type == 'subtitle'
          stream.instruction_types = [:drop]

        elsif stream.codec_type == 'video'
          stream.instruction_types = [:drop]

        elsif stream.codec_type == 'audio'
          stream.instruction_types = [:drop]

        else
          stream.instruction_types = [:drop]
        end



      end

    end

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

      table.render(:unicode) do |renderer|
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
