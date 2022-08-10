module MmTool

  #=============================================================================
  # A movie as a self contained class. Instances of this class consist of
  # one or more MmMovieStream instances, and contains intelligence about itself
  # so that it can provide commands to ffmpeg and/or mkvpropedit as required.
  # Upon creation it must be provided with a filename.
  #=============================================================================
  class MmMovie

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
    # Initialize
    #------------------------------------------------------------
    def initialize(with_file:)
      @defaults        = MmUserDefaults.shared_user_defaults
      @streams         = MmMovieStream::streams(with_files: all_paths(with_file: with_file))
      @format_metadata = FFMPEG::Movie.new(with_file).metadata[:format]
    end

    #------------------------------------------------------------
    # Get the file-level 'duration' metadata.
    #------------------------------------------------------------
    def format_duration
      seconds = @format_metadata[:duration]
      seconds ? Time.at(seconds.to_i).utc.strftime("%H:%M:%S") : nil
    end

    #------------------------------------------------------------
    # Get the file-level 'size' metadata.
    #------------------------------------------------------------
    def format_size
      size = @format_metadata[:size]
      size ? ByteSize.new(size) : 'unknown'
    end

    #------------------------------------------------------------
    # Get the file-level 'title' metadata.
    #------------------------------------------------------------
    def format_title
      @format_metadata&.dig(:tags, :title)
    end

    #------------------------------------------------------------
    # Indicates whether any of the streams are of a lower
    # quality than desired by the user.
    #------------------------------------------------------------
    def has_low_quality_streams?
      @streams.count {|stream| stream.low_quality?} > 0
    end

    #------------------------------------------------------------
    # Indicates whether or not a file has at least one high-
    # quality video stream and high-quality audio stream.
    #------------------------------------------------------------
    def meets_minimum_quality?
      @streams.count {|stream| stream.codec_type == 'audio' && !stream.low_quality? } > 0 &&
          @streams.count {|stream| stream.codec_type == 'video' && !stream.low_quality? } > 0
    end

    #------------------------------------------------------------
    # Indicates whether any of the streams are interesting.
    #------------------------------------------------------------
    def interesting?
      @streams.count {|stream| stream.interesting?} > 0 || format_title
    end

    #------------------------------------------------------------
    # Get the rendered text of the format_table.
    #------------------------------------------------------------
    def format_table
      unless @format_table
        @format_table = format_table_datasource.render(:basic) do |renderer|
          renderer.column_widths = [10,10, 160]
          renderer.multiline     = true
          renderer.padding       = [0,1]
          renderer.width         = 1000
        end
      end
      @format_table
    end

    #------------------------------------------------------------
    # For the given table, get the rendered text of the table
    # for output.
    #------------------------------------------------------------
    def stream_table
      unless @stream_table
        @stream_table = stream_table_datasource.render(:unicode) do |renderer|
          renderer.alignments    = [:center, :left, :left, :right, :right, :left, :left, :left, :left]
          renderer.column_widths = [5,10,10,5,10,5,23,50,35]
          renderer.multiline     = true
          renderer.padding       = [0,1]
          renderer.width         = 1000
        end # do
      end
      @stream_table
    end

    #------------------------------------------------------------
    # The complete command to rename the main input file to
    # include a tag indicating that it's the original.
    #------------------------------------------------------------
    def command_rename
      src = @streams[0].source_file
      dst = File.join(File.dirname(src), File.basename(src, '.*') + @defaults[:suffix] + File.extname(src))
      "mv \"#{src}\" \"#{dst}\""
    end

    #------------------------------------------------------------
    # The complete, proposed ffmpeg command to transcode the
    # input file to an output file. It uses the 'new_input_path'
    # as the input file.
    #------------------------------------------------------------
    def command_transcode
      command = ["ffmpeg \\"]
      command << "   -hide_banner \\"
      command << "   -loglevel error \\"
      command << "   -stats \\"
      @streams.each {|stream| command |= ["   #{stream.instruction_input}"] if stream.instruction_input }
      @streams.each {|stream| command << "   #{stream.instruction_map}" if stream.instruction_map }
      @streams.each {|stream| command << "   #{stream.instruction_action}" if stream.instruction_action }
      @streams.each {|stream| command << "   #{stream.instruction_disposition}" if stream.instruction_disposition }
      @streams.each do |stream|
        stream.instruction_metadata.each { |instruction| command << "   #{instruction}" }
      end

      command << "   -metadata title=\"#{format_title}\" \\" if format_title
      command << "   \"#{output_path}\""
      command.join("\n")
    end

    #------------------------------------------------------------
    # The complete command to view the output file after
    # running the transcode command
    #------------------------------------------------------------
    def command_review_post
      "\"#{$0}\" --no-use-external-subs \"#{output_path}\""
    end


    #============================================================
     private
    #============================================================

    #------------------------------------------------------------
    # Given the initial file, return an array of the initial
    # file and associated SRTs, which are valid if they have
    # no language, or a language specified in options.
    #------------------------------------------------------------
    def all_paths(with_file:)
      all_paths = [with_file]
      if @defaults[:use_external_subs]
        base_path = File.join(File.dirname(with_file), File.basename(with_file, '.*'))
        all_paths |= ([""] | @defaults[:keep_langs_subs]&.map {|lang| ".#{lang}" })
                         .select {|lang| File.file?("#{base_path}#{lang}.srt")}
                         .map {|lang| "#{base_path}#{lang}.srt"}
      end
      all_paths
    end

    #------------------------------------------------------------
    # The name of the proposed output file, if different from
    # the input file. This would be set in the event that the
    # container of the input file is not one of the approved
    # containers.
    #------------------------------------------------------------
    def output_path
      path = @streams[0].source_file
      if @defaults[:containers_preferred]&.include?(File.extname(path))
        path
      else
        File.join(File.dirname(path), File.basename(path, '.*') + '.' + @defaults[:containers_preferred][0])
      end
    end

    #------------------------------------------------------------
    # Return a TTY::Table of the relevant format data.
    #------------------------------------------------------------
    def format_table_datasource
      unless @format_table
        @format_table = TTY::Table.new(header: %w(Duration: Size: Title:))
        @format_table << [format_duration, format_size, format_title]
      end
      @format_table
    end

    #------------------------------------------------------------
    # Return a TTY::Table of the movie, populated with the
    # pertinent data of each stream.
    #------------------------------------------------------------
    def stream_table_datasource
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
          row << stream.action_label
          @table << row
        end
      end
      @table
    end # table

  end # class

end # module
