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
      @owner = from_movie
      @data = with_data
      @instruction_types = []
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def index
      @data[:index]
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def codec_name
      @data[:codec_name]
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def codec_type
      @data[:codec_type]
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def coded_width
      @data[:coded_width]
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def coded_height
      @data[:coded_height]
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def channels
      @data[:channels]
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def channel_layout
      @data[:channel_layout]
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def language
      if @data.key(:tags)
        lang = @data[:tags][:language]
        lang = @data[:tags][:LANGUAGE] unless lang
        lang = 'und' unless lang
      else
        lang = 'und'
      end
      lang
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def title
      if @data.key(:tags)
        @data[:tags][:title]
      else
        nil
      end
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def dispositions
      MmMovie.dispositions
          .collect {|symbol| @data[:disposition][symbol]}
          .join(',')
    end

    #------------------------------------------------------------
    # Property
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
    # Property
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
    # Property
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
    # Property
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
          d = title == nil

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
          e = title == nil
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
          d = title == nil
          e = @owner.owner[:scan_type] == 'quality' && low_quality?

          if (!a && !b && !c) || (a && !b && !c)
            @actions |= [:drop]
          end

          if (a && b) || (a && !b && !c)
            @actions |= [:copy]
          end

          if (!a && !b && c ) || (!a && b)
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


  end # MmMovieStream


end
