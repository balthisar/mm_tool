module MmTool

  #=============================================================================
  # A stream of an MmMovie. Instances contain simple accessors to the data
  # made available by ffmpeg, and have knowledge on how to generate useful
  # arguments for ffmpeg and mkvpropedit.
  #=============================================================================
  class MmMovieStream

    require 'streamio-ffmpeg'
    require 'mm_tool/mm_movie'

    #------------------------------------------------------------
    # Given an array of related files, this class method returns
    # an array of MmMovieStreams reflecting the streams present
    # in each of them.
    #------------------------------------------------------------
    def self.streams(with_files:)
      # Arrays are passed around by reference; when this array is created and
      # used as a reference in each stream, and *also* returned from this class
      # method, everyone will still be using the same reference. It's important
      # below to build up this array without replacing it with another instance.
      streams = []
      with_files.each_with_index do |path, i|
        ff_movie = FFMPEG::Movie.new(path)
        ff_movie.metadata[:streams].each do |stream|
          streams << MmMovieStream.new(stream_data: stream, source_file: path, file_number: i, streams_ref: streams)
        end
      end
      streams
    end

    #------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------
    def initialize(stream_data:, source_file:, file_number:, streams_ref:)
      @defaults    = MmUserDefaults.shared_user_defaults
      @data        = stream_data
      @source_file = source_file
      @file_number = file_number
      @streams     = streams_ref
    end

    #------------------------------------------------------------
    # Attribute accessors
    #------------------------------------------------------------
    attr_accessor :file_number
    attr_accessor :source_file

    #------------------------------------------------------------
    # Property - returns the index of the stream.
    #------------------------------------------------------------
    def index
      @data[:index]
    end

    #------------------------------------------------------------
    # Property - returns the input specifier of the stream.
    #------------------------------------------------------------
    def input_specifier
      "#{@file_number}:#{index}"
    end

    #------------------------------------------------------------
    # Property - returns the codec name of the stream.
    #------------------------------------------------------------
    def codec_name
      @data[:codec_name]
    end

    #------------------------------------------------------------
    # Property - returns the codec type of the stream.
    #------------------------------------------------------------
    def codec_type
      @data[:codec_type]
    end

    #------------------------------------------------------------
    # Property - returns the coded width of the stream.
    #------------------------------------------------------------
    def coded_width
      @data[:coded_width]
    end

    #------------------------------------------------------------
    # Property - returns the coded height of the stream.
    #------------------------------------------------------------
    def coded_height
      @data[:coded_height]
    end

    #------------------------------------------------------------
    # Property - returns the number of channels of the stream.
    #------------------------------------------------------------
    def channels
      @data[:channels]
    end

    #------------------------------------------------------------
    # Property - returns the channel layout of the stream.
    #------------------------------------------------------------
    def channel_layout
      @data[:channel_layout]
    end

    #------------------------------------------------------------
    # Property - returns the language of the stream, or 'und'
    #   if the language is not defined.
    #------------------------------------------------------------
    def language
      if @data.key?(:tags)
        lang = @data[:tags][:language]
        lang = @data[:tags][:LANGUAGE] unless lang
        lang = 'und' unless lang
      else
        lang = 'und'
      end
      lang
    end

    #------------------------------------------------------------
    # Property - returns the title of the stream, or nil.
    #------------------------------------------------------------
    def title
      if @data.key?(:tags)
        @data[:tags][:title]
      else
        nil
      end
    end

    #------------------------------------------------------------
    # Property - returns the disposition flags of the stream as
    #   a comma-separated list for compactness.
    #------------------------------------------------------------
    def dispositions
      MmMovie.dispositions
          .collect {|symbol| @data[:disposition][symbol]}
          .join(',')
    end

    #------------------------------------------------------------
    # Property - returns an appropriate "quality" indicator
    #   based on the type of the stream.
    #------------------------------------------------------------
    def quality_01
      if codec_type == 'audio'
        channels
      elsif codec_type == 'video'
        coded_width
      else
        nil
      end
    end

    #------------------------------------------------------------
    # Property - returns a different appropriate "quality"
    #   indicator based on the type of the stream.
    #------------------------------------------------------------
    def quality_02
      if codec_type == 'audio'
        channel_layout
      elsif codec_type == 'video'
        coded_height
      else
        nil
      end
    end

    #------------------------------------------------------------
    # Property - returns a convenient label indicating the
    #   recommended actions for the stream.
    #------------------------------------------------------------
    def action_label
      "#{output_specifier} #{actions.select {|a| a != :interesting}.join(' ')}"
    end

    #------------------------------------------------------------
    # Property - indicates whether or not the stream is the
    #   default stream per its dispositions.
    #------------------------------------------------------------
    def default?
      @data[:disposition][:default] == 1
    end

    #------------------------------------------------------------
    # Property - indicates whether or not the stream is
    #   considered "low quality" based on the application
    #   configuration.
    #------------------------------------------------------------
    def low_quality?
      if codec_type == 'audio'
        channels.to_i < @defaults[:min_channels].to_i
      elsif codec_type == 'video'
        coded_width.to_i < @defaults[:min_width].to_i
      else
        false
      end
    end

    #------------------------------------------------------------
    # Property - stream action includes :drop?
    #------------------------------------------------------------
    def drop?
      actions.include?(:drop)
    end

    #------------------------------------------------------------
    # Property - stream action includes :copy?
    #------------------------------------------------------------
    def copy?
      actions.include?(:copy)
    end

    #------------------------------------------------------------
    # Property - stream action includes :transcode?
    #------------------------------------------------------------
    def transcode?
      actions.include?(:transcode)
    end

    #------------------------------------------------------------
    # Property - stream action includes :set_language?
    #------------------------------------------------------------
    def set_language?
      actions.include?(:set_language)
    end

    #------------------------------------------------------------
    # Property - stream action includes :interesting?
    #------------------------------------------------------------
    def interesting?
      actions.include?(:interesting)
    end

    #------------------------------------------------------------
    # Property - indicates whether or not the stream will be
    #   unique for its type at output.
    #------------------------------------------------------------
    def output_unique?
      @streams.count {|s| s.codec_type  == codec_type && !s.drop? } == 1
    end

    #------------------------------------------------------------
    # Property - indicates whether or not this stream is the
    #   only one of its type.
    #------------------------------------------------------------
    def one_of_a_kind?
      @streams.count {|s| s.codec_type  == codec_type && s != self } == 0
    end

    #------------------------------------------------------------
    # Property - returns the index of the stream in the output
    #   file.
    #------------------------------------------------------------
    def output_index
      @streams.select {|s| !s.drop? }.index(self)
    end

    #------------------------------------------------------------
    # Property - returns a specific output specifier for the
    #   stream, such as v:0 or a:2.
    #------------------------------------------------------------
    def output_specifier
      idx = @streams.select {|s| s.codec_type == codec_type && !s.drop?}.index(self)
      idx ? "#{codec_type[0]}:#{idx}" : ' ⬇ '
    end

    #------------------------------------------------------------
    # Property - returns the -i input instruction for this
    #   stream.
    #------------------------------------------------------------
    def instruction_input
      src = if @file_number == 0
              File.join(File.dirname(@source_file), File.basename(@source_file, '.*') + @defaults[:suffix] + File.extname(@source_file))
            else
              @source_file
            end
      "-i \"#{src}\" \\"
    end

    #------------------------------------------------------------
    # Property - returns the -map instruction for this stream,
    #   according to the action(s) determined.
    #------------------------------------------------------------
    def instruction_map
      drop? ? nil : "-map #{input_specifier} \\"
    end

    #------------------------------------------------------------
    # Property - returns an instruction for handling the stream,
    #   according to the action(s) determined.
    #------------------------------------------------------------
    def instruction_action
      if copy?
        "-codec:#{output_specifier} copy \\"
      elsif transcode?
        if codec_type == 'audio'
          encode_to = @defaults[:codecs_audio_preferred][0]
        elsif codec_type == 'video'
          encode_to = @defaults[:codecs_video_preferred][0]
        else
          raise Exception.new "Error: somehow the program branched where it shouldn't have."
        end
        "-codec:#{output_specifier} #{encoder_string(for_codec: encode_to)} \\"
      else
        nil
      end
    end

    #------------------------------------------------------------
    # Property - returns an instruction for setting the metadata
    #   of the stream, if necessary.
    #------------------------------------------------------------
    def instruction_metadata
      # We only want to set fixed_lang if options allow us to fix the language,
      # and we want to set subtitle language from the filename, if applicable.
      fixed_lang = @defaults[:fix_undefined_language] ? @defaults[:undefined_language] : nil
      lang = subtitle_file_language ? subtitle_file_language : fixed_lang
      set_language = set_language? ? "language=#{lang} " : nil
      set_title = title  && ! @defaults[:ignore_titles] ? "title=\"#{title}\" " : nil

      if set_language || set_title
        "-metadata:s:#{output_specifier} #{set_language}#{set_title}\\"
      else
        nil
      end
    end

    #------------------------------------------------------------
    # Property - returns an instruction for setting the stream's
    #   default disposition, if necessary.
    #------------------------------------------------------------
    def instruction_disposition
      set_disposition = output_unique? && !default? && !drop? ? "default " : nil

      if set_disposition
        "-disposition:#{output_specifier} #{set_disposition}\\"
      else
        nil
      end
    end


    #============================================================
     private
    #============================================================


    #------------------------------------------------------------
    # Property - returns an array of actions that are suggested
    #   for the stream based on quality, language, codec, etc.
    #------------------------------------------------------------
    def actions

      #------------------------------------------------------------
      # Note: logic below a result of Karnaugh mapping of the
      # selection truth table for each desired action. There's
      # probably an excel file somewhere in the repository.
      #------------------------------------------------------------

      if @actions.nil?
        @actions = []

        #––––––––––––––––––––––––––––––––––––––––––––––––––
        # subtitle stream handler
        #––––––––––––––––––––––––––––––––––––––––––––––––––
        if codec_type == 'subtitle'

          a = @defaults[:keep_langs_subs]&.include?(language)
          b = @defaults[:codecs_subs_preferred]&.include?(codec_name)
          c = language.downcase == 'und'
          d = title != nil && ! @defaults[:ignore_titles]

          if (!a && !c) || (!b)
            @actions |= [:drop]
          else
            @actions |= [:copy]
          end

          if (b && c) && (@defaults[:fix_undefined_language])
            @actions |= [:set_language]
          end

          if (!a || !b || c || (d))
            @actions |= [:interesting]
          end

        #––––––––––––––––––––––––––––––––––––––––––––––––––
        # video stream handler
        #––––––––––––––––––––––––––––––––––––––––––––––––––
        elsif codec_type == 'video'

          a = codec_name.downcase == 'mjpeg'
          b = @defaults[:codecs_video_preferred]&.include?(codec_name)
          c = @defaults[:keep_langs_video]&.include?(language)
          d = language.downcase == 'und'
          e = title != nil && ! @defaults[:ignore_titles]
          f = @defaults[:scan_type] == 'quality' && low_quality?

          if (a)
            @actions |= [:drop]
          end

          if (!a && b)
            @actions |= [:copy]
          end

          if (!a && !b)
            @actions |= [:transcode]
          end

          if (!a && d) && (@defaults[:fix_undefined_language])
            @actions |= [:set_language]
          end

          if (a || !b || !c || d || e || f)
            @actions |= [:interesting]
          end

        #––––––––––––––––––––––––––––––––––––––––––––––––––
        # audio stream handler
        #––––––––––––––––––––––––––––––––––––––––––––––––––
        elsif codec_type == 'audio'

          a = @defaults[:codecs_audio_preferred]&.include?(codec_name)
          b = @defaults[:keep_langs_audio]&.include?(language)
          c = language.downcase == 'und'
          d = title != nil && ! @defaults[:ignore_titles]
          e = @defaults[:scan_type] == 'quality' && low_quality?

          if (!b && !c)
            @actions |= one_of_a_kind? ? [:set_language] : [:drop]
          end

          if (a && b) || (a && !b && c)
            @actions |= [:copy]
          end

          if (!a && !b && c) || (!a && b)
            @actions |= [:transcode]
          end

          if (c) && (@defaults[:fix_undefined_language])
            @actions |= [:set_language]
          end

          if (!a || !b || c || d || e)
            @actions |= [:interesting]
          end

          #––––––––––––––––––––––––––––––––––––––––––––––––––
          # other stream handler
          #––––––––––––––––––––––––––––––––––––––––––––––––––
        else
          @actions |= [:drop]
        end
      end # if @actions.nil?

      @actions
    end # actions

    #------------------------------------------------------------
    # Given a codec, return the ffmpeg encoder string.
    #------------------------------------------------------------
    def encoder_string(for_codec:)
      case for_codec.downcase
      when 'hevc'
        "libx265 -crf 28 -preset slow"
      when 'h264'
        "libx264 -crf 23 -preset slow"
      when 'aac'
        "libfdk_aac"
      else
        raise Exception.new "Error: somehow an unsupported codec '#{for_codec}' was specified."
      end
    end

    #------------------------------------------------------------
    # If the source file is an srt, and there's a language, and
    # it's in the approved language list, then return it;
    # otherwise return nil.
    #------------------------------------------------------------
    def subtitle_file_language
      langs = @defaults[:keep_langs_subs]&.join('|')
      lang = @source_file.match(/^.*\.(#{langs})\.srt$/)
      lang ? lang[1] : nil
    end

  end # class

end # module
