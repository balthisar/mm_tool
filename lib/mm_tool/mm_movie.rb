module MmTool

  #=============================================================================
  # A movie as a self contained class. Instances of this class consist of
  # one or more MmMovieStream instances, and contains intelligence about itself
  # so that it can provide commands to ffmpeg and/or mkvpropedit as required.
  # Upon creation it must be provided with a filename and an owner.
  #=============================================================================
  class MmMovie

    require 'mm_tool/mm_movie_stream'
    require 'streamio-ffmpeg'
    require 'tty-table'
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
    attr_reader :owner               # Exposed owner.
    attr_reader :ff_movie            # Exposed instance of the FFMPEG::Movie
    attr_reader :streams             # Exposed array of MmMovieStream.

    #------------------------------------------------------------
    # Define and setup instance variables.
    #------------------------------------------------------------
    def initialize(with_file:, owner:)
      @path     = with_file
      @owner    = owner

      # Before we create the movie instance and its streams proper, we'll get all of
      # the streams from any subtitle files that are lying around, and then add them
      # the the main file's streams later, after creating them.
      subtitle_streams = []
      srt_paths.each_with_index do |path, i|
        @ff_movie = FFMPEG::Movie.new(path)
        subtitle_streams |= MmMovieStream::streams(from_movie: self).each {|s| s.file_number = i+1}
      end

      @ff_movie = FFMPEG::Movie.new(with_file)
      @streams  = MmMovieStream::streams(from_movie: self) | subtitle_streams
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
    # Get the file-level 'title' metadata.
    #------------------------------------------------------------
    def format_title
      @ff_movie&.metadata&.dig(:format, :tags, :title)
    end

    #------------------------------------------------------------
    # Return a TTY::Table of the format data, above.
    #------------------------------------------------------------
    def format_table
      unless @format_table
        @format_table = TTY::Table.new(header: %w(Duration: Size: Title:))
        @format_table << [format_duration, format_size, format_title]
      end
      @format_table
    end

    #------------------------------------------------------------
    # Get the rendered text of the format_table.
    #------------------------------------------------------------
    def format_table_text
      unless @format_table_text
        @format_table_text = format_table.render(:basic) do |renderer|
          renderer.column_widths = [10,10, 160]
          renderer.multiline     = true
          renderer.padding       = [0,1]
          renderer.width         = 1000
        end
      end
      @format_table_text
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
          row << stream.input_specifier
          row << stream.codec_name
          row << stream.codec_type
          row << stream.quality_01
          row << stream.quality_02
          row << stream.language
          row << stream.dispositions
          row << stream.title
          row << "#{stream.output_specifier} #{stream.actions.select {|a| a != :interesting}.join(' ')}"
          @table << row
        end
      end
      @table
    end # table

    #------------------------------------------------------------
    # For the given table, get the rendered text of the table
    # for output.
    #------------------------------------------------------------
    def table_text
      unless @table_text
        @table_text = table.render(:unicode) do |renderer|
          renderer.alignments    = [:center, :left, :left, :right, :right, :left, :left, :left, :left]
          renderer.column_widths = [5,10,10,5,10,5,23,50,35]
          renderer.multiline     = true
          renderer.padding       = [0,1]
          renderer.width         = 1000
        end # do
      end

      @table_text
    end


    #------------------------------------------------------------
    # If there are adjacent SRTs without a language, or with a
    # language specified in options, then this array will have
    # them.
    #------------------------------------------------------------
    def srt_paths
      if @srt_paths.nil?
        base_path = File.join(File.dirname(@path), File.basename(@path, '.*'))
        @srt_paths = ([""] | @owner[:keep_langs_subs].map {|lang| ".#{lang}" })
            .select {|lang| File.file?("#{base_path}#{lang}.srt")}
            .map {|lang| "#{base_path}#{lang}.srt"}
      end
      @srt_paths
    end

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
      extra_inputs = @streams.select {|s| s.file_number > 0 }.map {|s| s.instruction_input}

      command << "ffmpeg -i \"#{new_input_path}\" \\"
      extra_inputs.each {|i| command << "       #{i} \\" if extra_inputs.count > 0 }
      @streams.each {|stream| command << "   #{stream.instruction_map}" if stream.instruction_map }
      @streams.each {|stream| command << "   #{stream.instruction_action}" if stream.instruction_action }
      @streams.each {|stream| command << "   #{stream.instruction_disposition}" if stream.instruction_disposition }
      @streams.each {|stream| command << "   #{stream.instruction_metadata}" if stream.instruction_metadata }
      command << "   -metadata title=\"#{format_title}\"" if format_title
      command << "   \"#{output_path}\""
      command.join("\n")
    end

    #------------------------------------------------------------
    # Indicates whether any of the streams are of a lower
    # quality than desired by the user.
    #------------------------------------------------------------
    def low_quality?
      streams.count {|stream| stream.low_quality?} > 0
    end

    #------------------------------------------------------------
    # Indicates whether any of the streams are interesting.
    #------------------------------------------------------------
    def interesting?
      streams.count {|stream| stream.actions.include?(:interesting)} > 0 || format_title
    end

  end # class MmMovie

end # module MmTool
