################################################################################
# MmTool
#  The main application performs all of the work.
################################################################################
module MmTool

  require 'pastel'

  class ApplicationMain

    #======================================================
    # Define and setup module level variables.
    #======================================================
    def initialize
      p = Pastel.new(enabled: $stdout.tty? && $stderr.tty?)
      @options = {

          #----------------------------
          # Main Options
          #----------------------------

          :help => {
              :default    => nil,
              :value      => nil,
              :arg_short  => '-h',
              :arg_long   => '--help',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Shows this help information
              HEREDOC
          },

          :container_files => {
              :default    => %w(mp4 mkv avi 3gp flv),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--containers',
              :arg_format => '<extensions>',
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of file extensions assumed to be media files. The default is #{p.bold('%s')}.
              HEREDOC
          },

          :skip_boring => {
              :default    => FalseClass,
              :value      => nil,
              :arg_short  => '-s',
              :arg_long   => '--skip-boring-files',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Don't show uninteresting files in the output. Uninteresting files meet all of our requirements, and
                can clutter up the display.
              HEREDOC
          },

          :verbose => {
              :default    => FalseClass,
              :value      => nil,
              :arg_short  => '-v',
              :arg_long   => '--verbose',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Show media information for every file, instead of just files that trigger messages.
              HEREDOC
          },

          :version => {
              :default    => FalseClass,
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--version',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Show version of this program.
              HEREDOC
          },

          :xml => {
              :default    => FalseClass,
              :value      => nil,
              :arg_short  => '-x',
              :arg_long   => '--xml',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Show the raw XML information for the media file instead of the summary table. This implies
                #{p.bold('--no-transcode')}.
              HEREDOC
          },

          :stop_processing => {
              :default    => FalseClass,
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Stops further processing of input arguments, which can be useful in scripting environments.
              HEREDOC
          },

          #----------------------------
          # Media Options
          #----------------------------

          :containers_preferred => {
              :default    => %w(mkv mp4),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--containers-preferred',
              :arg_format => '<extensions>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of file extensions defining preferred media containers. If the container
                is not one of these types, then it will be reported. If #{p.bold('--transcode')} is specified, and
                a file is a non-preferred container, then it will be transcoded to the #{p.underline('first')} item
                in this list. The default is #{p.bold('%s')}.
              HEREDOC
          },

          :codec_audio_preferred => {
              :default    => %w(aac ac3 eac3),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--codec-audio-preferred',
              :arg_format => '<codecs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{p.bold('--transcode')} is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{p.underline('first')} item in this list. The default
                is #{p.bold('%s')}.
              HEREDOC
          },

          :codec_video_preferred => {
              :default    => %w(hevc h265 h264),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--codec-video-preferred',
              :arg_format => '<codecs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{p.bold('--transcode')}  is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{p.underline('first')} item in this list. The default
                is #{p.bold('%s')}.
              HEREDOC
          },

          :codec_subs_preferred => {
              :default    => %w(subrip mov_text),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--codec-subs-preferred',
              :arg_format => '<codecs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{p.bold('--transcode')}  is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{p.underline('first')} item in this list. The default
                is #{p.bold('%s')}.
              HEREDOC
          },

          :keep_langs_audio => {
              :default    => %w(und eng spa chi zho),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--keep-langs-audio',
              :arg_format => '<langs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of languages whose audio streams should not be discarded. If
                #{p.bold('--transcode')} is specified, audio streams with languages that are not on this list
                will be discarded unless it is the only stream. Use the special language code  #{p.bold('und')}
                to ensure that streams without a designated language are not discarded! The default is #{p.bold('%s')}.
              HEREDOC
          },

          :keep_langs_video => {
              :default    => %w(und eng spa chi zho),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--keep-langs-video',
              :arg_format => '<langs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of languages whose video streams should not be discarded. If
                #{p.bold('--transcode')} is specified, video streams with languages that are not on this list
                will be discarded unless it is the only stream. Use the special language code  #{p.bold('und')}
                to ensure that streams without a designated language are not discarded! The default is #{p.bold('%s')}.
              HEREDOC
          },

          :keep_langs_subs => {
              :default    => %w(und eng spa chi zho),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--keep-langs-subs',
              :arg_format => '<langs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of languages whose subtitles should not be discarded. If
                #{p.bold('--transcode')} is specified, subtitles of languages that are not on this list
                will be discarded. Use the special language code  #{p.bold('und')} to ensure that streams
                without a designated language are not discarded! The default is #{p.bold('%s')}.
                See also #{p.bold('--codec-subs-preferred')}, whose condition is AND with this condition
                (both must be true to pass through the subtitle).
              HEREDOC
          },

          #----------------------------
          # Transcoding Options
          #----------------------------

          :transcode => {
              :default    => FalseClass,
              :value      => nil,
              :arg_short  => '-t',
              :arg_long   => '--transcode',
              :arg_format => nil,
              :help_group => 'Transcoding Options',
              :help_desc  => <<~HEREDOC
                Perform transcoding if necessary. Containers and streams that are not in preferred formats will be
                transcoded; streams that are not in the preferred language will be dropped, unless they are the
                only video or only audio stream.
              HEREDOC
          },

          :drop_subs => {
              :default    => FalseClass,
              :value      => nil,
              :arg_short  => '-d',
              :arg_long   => '--drop-subs',
              :arg_format => nil,
              :help_group => 'Transcoding Options',
              :help_desc  => <<~HEREDOC
                When specified, this script will drop all subtitles from files in the population, regardless of
                the language. This directive has no effect if #{p.bold('--transcode')} is not specifed.
              HEREDOC
          },

          :suffix => {
              :default    => '-original',
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--suffix',
              :arg_format => '<suffix>',
              :help_group => 'Transcoding Options',
              :help_desc  => <<~HEREDOC
                When #{p.bold('--transcode')} is specified, new files will be written using the original filename
                and applicable extension, and the original file will be renamed plus this suffix. The default
                is #{p.bold('%s')}.
              HEREDOC
          },

          :undefined_language => {
              :default    => 'eng',
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--undefined-language',
              :arg_format => '<lang>',
              :help_group => 'Transcoding Options',
              :help_desc  => <<~HEREDOC
                When #{p.bold('--transcode')} is specified, streams in the new file that have an undefined language
                identified will be set to this option's value. The default is #{p.bold('%s')}.
              HEREDOC
          },

          :fix_undefined_language => {
              :default    => TrueClass,
              :value      => nil,
              :arg_short  => 'u',
              :arg_long   => '--no-fix-undefined-language',
              :arg_format => nil,
              :help_group => 'Transcoding Options',
              :help_desc  => <<~HEREDOC
                Prevent this program from fixing undefined languages assigned to streams. See #{p.bold('--undefined-language')}.
              HEREDOC
          },

          #----------------------------
          # Quality Options
          #----------------------------

          :quality_reports => {
              :default    => TrueClass,
              :value      => nil,
              :arg_short  => '-w',
              :arg_long   => '--no-quality-reports',
              :arg_format => nil,
              :help_group => 'Quality Options',
              :help_desc  => <<~HEREDOC
                Don't report files that merely are low quality. Such files are still inspected for non-preferred
                streams and subtitles. They simply will be skipped if the only issues are resolution and/or number of
                audio channels.
              HEREDOC
          },

          :min_width => {
              :default    => '1920',
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--min-width',
              :arg_format => '<width>',
              :help_group => 'Quality Options',
              :help_desc  => <<~HEREDOC
                Specify the minimum width that is considered acceptable quality. The default is #{p.bold('%s')}.
              HEREDOC
          },

          :min_channels => {
              :default    => '6',
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--min-channels',
              :arg_format => '<channels>',
              :help_group => 'Quality Options',
              :help_desc  => <<~HEREDOC
                Specify the minimum number of audio channels that are considered acceptable quality. The default is #{p.bold('%s')}.
              HEREDOC
          },
      }
    end # initialize


    #======================================================
    # property options
    #======================================================
    def options
      @options
    end


    #======================================================
    # Get the value of a setting by key.
    #======================================================
    def [](key)
      if @options.key?(key)
        return @options[key][:value] ? @options[key][:value] : @options[key][:default]
      else
        return nil
      end
    end


    #======================================================
    # Set the value of a setting by key.
    #======================================================
    def []=(key, val)
      if @options.key?(key)
        @options[key][:value] = val
      else
        raise "Error: setting “#{key}” doesn't exist."
      end
    end


    #======================================================
    # Singleton accessor.
    #======================================================
    def self.sharedApplication
      unless @self
        @self = self.new
      end
      @self
    end

  end # class ApplicationMain

end # module MmTool
