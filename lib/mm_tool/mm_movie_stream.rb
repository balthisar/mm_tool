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
    # Given an MmMovie, this class method returns an array
    # of streams.
    #------------------------------------------------------------
    def self.streams(from_movie:)
      unless from_movie.class == MmTool::MmMovie
        raise Exception.new "Error: parameter must be an MmTool::MmMovie instance."
      end
      from_movie.ff_movie.metadata[:streams].collect do |stream|
        MmMovieStream.new(with_data: stream, from_movie: from_movie)
      end
    end

    #------------------------------------------------------------
    # Define and setup instance variables.
    #------------------------------------------------------------
    def initialize(with_data:, from_movie:)
      unless from_movie.class == MmTool::MmMovie
        raise Exception.new "Error: parameter must be an MmTool::MmMovie instance."
      end
      @data        = with_data
      @owner       = from_movie
    end

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
      "#{file_number}:#{index}"
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
    # Property - the file number, when multiple files are
    #   specified.
    #------------------------------------------------------------
    def file_number
      if @file_number.nil?
        @file_number = 0
      end
      @file_number
    end

    def file_number=(number)
      @file_number = number
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
        channels.to_i < @owner.owner[:min_channels].to_i
      elsif codec_type == 'video'
        coded_width.to_i < @owner.owner[:min_width].to_i
      else
        false
      end
    end

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

          a = @owner.owner[:keep_langs_subs].include?(language)
          b = @owner.owner[:codecs_subs_preferred].include?(codec_name)
          c = language.downcase == 'und'
          d = title != nil

          if (!a && !b) || (!a && !c) || (a && !b)
            @actions |= [:drop]
          else
            @actions |= [:copy]
          end

          if (b && c)
            @actions |= [:set_language]
          end

          if (!a || !b || c || d)
            @actions |= [:interesting]
          end

          #––––––––––––––––––––––––––––––––––––––––––––––––––
          # video stream handler
          #––––––––––––––––––––––––––––––––––––––––––––––––––
        elsif codec_type == 'video'

          a = codec_name.downcase == 'mjpeg'
          b = @owner.owner[:codecs_video_preferred].include?(codec_name)
          c = @owner.owner[:keep_langs_video].include?(language)
          d = language.downcase == 'und'
          e = title != nil
          f = @owner.owner[:scan_type] == 'quality' && low_quality?

          if (a)
            @actions |= [:drop]
          end

          if (!a && b)
            @actions |= [:copy]
          end

          if (!a && !b)
            @actions |= [:transcode]
          end

          if (!a && d)
            @actions |= [:set_language]
          end

          if (a || !b || !c || d || e || f)
            @actions |= [:interesting]
          end

          #––––––––––––––––––––––––––––––––––––––––––––––––––
          # audio stream handler
          #––––––––––––––––––––––––––––––––––––––––––––––––––
        elsif codec_type == 'audio'

          a = @owner.owner[:codecs_audio_preferred].include?(codec_name)
          b = @owner.owner[:keep_langs_audio].include?(language)
          c = language.downcase == 'und'
          d = title != nil
          e = @owner.owner[:scan_type] == 'quality' && low_quality?

          if (!a && !b && !c) || (a && !b && !c)
            @actions |= [:drop]
          end

          if (a && b) || (a && !b && !c)
            @actions |= [:copy]
          end

          if (!a && !b && c) || (!a && b)
            @actions |= [:transcode]
          end

          if (c)
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
    # Property - indicates whether or not the stream will be
    #   unique for its type at output.
    #------------------------------------------------------------
    def output_unique?
      @owner.streams.count {|s| s.codec_type  == codec_type && !s.actions.include?(:drop) } == 1
    end

    #------------------------------------------------------------
    # Property - returns the index of the stream in the output
    #   file.
    #------------------------------------------------------------
    def output_index
      @owner.streams.select {|s| !s.actions.include?(:drop) }.index(self)
    end

    #------------------------------------------------------------
    # Property - returns a specific output specifier for the
    #   stream, such as v:0 or a:2.
    #------------------------------------------------------------
    def output_specifier
      idx = @owner.streams.select {|s| s.codec_type == codec_type && !s.actions.include?(:drop)}.index(self)
      "#{codec_type[0]}:#{idx}"
    end

    #------------------------------------------------------------
    # Property - returns the -map instruction for this stream,
    #   according to the action(s) determined.
    #------------------------------------------------------------
    def instruction_map
      actions.include?(:drop) ? nil : "-map #{input_specifier} \\"
    end

    #------------------------------------------------------------
    # Property - returns an instruction for handling the stream,
    #   according to the action(s) determined.
    #------------------------------------------------------------
    def instruction_action
      if actions.include?(:copy)
        "-codec:#{output_specifier} copy \\"
      elsif actions.include?(:transcode)
        if codec_type == 'audio'
          encode_to = @owner.owner[:codecs_audio_preferred][0]
        elsif codec_type == 'video'
          encode_to = @owner.owner[:codecs_video_preferred][0]
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
      set_language = actions.include?(:set_language) ? "language=#{@owner.owner[:undefined_language]} " : nil
      set_title = title ? "title=\"#{title}\" " : nil

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
      set_disposition = output_unique? && !default? ? "default " : nil

      if set_disposition
        "-disposition:#{output_specifier} #{set_disposition}\\"
      else
        nil
      end
    end


    private


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

  end # MmMovieStream


end
