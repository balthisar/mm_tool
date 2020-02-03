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
    # Define and setup module level variables.
    #------------------------------------------------------------
    def initialize(with_data:, from_movie:)
      @owner = from_movie
      @data = with_data
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
      lang = @data[:tags][:language]
      lang = @data[:tags][:LANGUAGE] unless lang
      lang = 'und' unless lang
      lang
    end

    #------------------------------------------------------------
    # Property
    #------------------------------------------------------------
    def title
      @data[:tags][:title]
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
      end
    end


  end # MmMovieStream


end
