module MmTool

  #=============================================================================
  # This module consolidates all of the default options for MmTool.
  #=============================================================================

  PATH_IGNORE_LIST   = File.join(Dir.home, '.mm_tool', 'ignored_file_list.txt')
  PATH_USER_DEFAULTS = File.join(Dir.home, '.mm_tool', 'com.balthisar.mm_tool.rc')

  #noinspection RubyResolve
  USER_DEFAULTS = {

      #----------------------------
      # Main Options
      #----------------------------

      :help => {
          :default    => nil,
          :value      => nil,
          :arg_short  => '-h',
          :arg_long   => '--help',
          :arg_format => nil,
          :item_label => nil,
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
          :item_label => 'Media Filetypes',
          :help_group => 'Main Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of file extensions assumed to be media files when examining directories. The
                default is #{C.bold('%s')}. You can still pass individual files, such as subtitles, that are different
                container formats.
          HEREDOC
      },

      :scan_type => {
          :default    => 'normal',
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--scan',
          :arg_format => '<scan_type>',
          :item_label => 'Scan Type',
          :help_group => 'Main Options',
          :help_desc  => <<~HEREDOC
                Type of files for which to show results, when this program is given a directory. #{C.bold('normal')}
                will display results of files that have some change proposed to them, or have some other characteristic
                that merits review. #{C.bold('all')} will display all media files, even if there's nothing interesting
                about them (however, ignore-flagged files will be ignored. #{C.bold('flagged')} will show data for all
                ignore-flagged files. #{C.bold('quality')} will show results only for files not meeting quality
                thresholds. The default is #{C.bold('%s')}.
          HEREDOC
      },

      :ignore_titles => {
          :default    => false,
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--ignore-titles',
          :arg_format => nil,
          :item_label => 'Ignore Title Metadata',
          :help_group => 'Main Options',
          :help_desc  => <<~HEREDOC
                This program normally finds that files or streams with titles are interesting, because they're usually
                mangled or have scene information. Once you've curated your library, though, they can clutter up the
                results of this program. Set this option to ignore titles when deciding to show you a file or not.
          HEREDOC
      },

      :info_header => {
          :default    => true,
          :value      => nil,
          :arg_short  => '-i',
          :arg_long   => '--no-info-header',
          :arg_format => nil,
          :item_label => nil,
          :help_group => 'Main Options',
          :help_desc  => <<~HEREDOC
                Don't show the information header indicating much of the configuration at the beginning of the output.
          HEREDOC
      },

      :shell_commands => {
          :default    => true,
          :value      => nil,
          :arg_short  => '-s',
          :arg_long   => '--no-shell-commands',
          :arg_format => nil,
          :item_label => nil,
          :help_group => 'Main Options',
          :help_desc  => <<~HEREDOC
                Don't show the shell commands that should be executed at the end of the output. Good for showing the table only.
          HEREDOC
      },

      :version => {
          :default    => false,
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--version',
          :arg_format => nil,
          :help_group => 'Main Options',
          :help_desc  => <<~HEREDOC
                Show version of this program.
          HEREDOC
      },

      #----------------------------
      # Command-like Options
      #----------------------------

      :ignore_files => {
          :default    => false,
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--ignore-files',
          :arg_format => nil,
          :item_label => nil,
          :help_group => 'Command-like Options',
          :help_desc  => <<~HEREDOC
                Files following this command will not be inspected; instead, they will be added to the persistent list
                of files to be ignored. You can use #{C.bold('--no-ignore-files')} to flip this flag back off for
                subsequent files on the command line.
          HEREDOC
      },

      :unignore_files => {
          :default    => false,
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--unignore-files',
          :arg_format => nil,
          :item_label => nil,
          :help_group => 'Command-like Options',
          :help_desc  => <<~HEREDOC
                Files following this command will be removed from the persistent list of files to be ignored.
                You can use #{C.bold('--no-unignore-files')} to flip this flag back off for subsequent files on the
                command line.
          HEREDOC
      },

      :transcode => {
          :default    => false,
          :value      => nil,
          :arg_short  => '-t',
          :arg_long   => '--transcode',
          :arg_format => nil,
          :item_label => 'Emit Transcode Script',
          :help_group => 'Command-like Options',
          :help_desc  => <<~HEREDOC
                Write transcoding instructions. Containers and streams that are not in preferred formats will be
                transcoded; streams that are not in the preferred language will be dropped, unless they are the
                only video or only audio stream. Transcoding instructions will be written to a temporary file.
          HEREDOC
      },

      :stop_processing => {
          :default    => false,
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--',
          :arg_format => nil,
          :item_label => nil,
          :help_group => 'Command-like Options',
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
          :item_label => 'Preferred Containers',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of file extensions defining preferred media containers. If the container
                is not one of these types, then it will be reported. If #{C.bold('--transcode')} is specified, and
                a file is a non-preferred container, then it will be transcoded to the #{C.underline('first')} item
                in this list. The default is #{C.bold('%s')}.
          HEREDOC
      },

      :codecs_audio_preferred => {
          :default    => %w(aac ac3 eac3),
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--codecs-audio-preferred',
          :arg_format => '<codecs>',
          :item_label => 'Preferred Audio Codecs',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{C.bold('--transcode')} is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{C.underline('first')} item in this list. The default
                is #{C.bold('%s')}.
          HEREDOC
      },

      :codecs_video_preferred => {
          :default    => %w(hevc h265 h264),
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--codecs-video-preferred',
          :arg_format => '<codecs>',
          :item_label => 'Preferred Video Codecs',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{C.bold('--transcode')}  is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{C.underline('first')} item in this list. The default
                is #{C.bold('%s')}.
          HEREDOC
      },

      :codecs_subs_preferred => {
          :default    => %w(subrip mov_text),
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--codecs-subs-preferred',
          :arg_format => '<codecs>',
          :item_label => 'Preferred Subtitle Codecs',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{C.bold('--transcode')}  is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{C.underline('first')} item in this list. The default
                is #{C.bold('%s')}.
          HEREDOC
      },

      :keep_langs_audio => {
          :default    => %w(und eng spa chi zho),
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--keep-langs-audio',
          :arg_format => '<langs>',
          :item_label => 'Keep Audio Languages',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of languages whose audio streams should not be discarded. If
                #{C.bold('--transcode')} is specified, audio streams with languages that are not on this list
                will be discarded unless it is the only stream. Use the special language code  #{C.bold('und')}
                to ensure that streams without a designated language are not discarded! The default is #{C.bold('%s')}.
          HEREDOC
      },

      :keep_langs_video => {
          :default    => %w(und eng spa chi zho),
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--keep-langs-video',
          :arg_format => '<langs>',
          :item_label => 'Keep Video Languages',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of languages whose video streams should not be discarded. If
                #{C.bold('--transcode')} is specified, video streams with languages that are not on this list
                will be discarded unless it is the only stream. Use the special language code  #{C.bold('und')}
                to ensure that streams without a designated language are not discarded! The default is #{C.bold('%s')}.
          HEREDOC
      },

      :keep_langs_subs => {
          :default    => %w(und eng spa chi zho),
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--keep-langs-subs',
          :arg_format => '<langs>',
          :item_label => 'Keep Subtitle Languages',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                A comma-separated list of languages whose subtitles should not be discarded. If
                #{C.bold('--transcode')} is specified, subtitles of languages that are not on this list
                will be discarded. Use the special language code  #{C.bold('und')} to ensure that streams
                without a designated language are not discarded! The default is #{C.bold('%s')}.
                See also #{C.bold('--codec-subs-preferred')}, whose condition is AND with this condition
                (both must be true to pass through the subtitle).
          HEREDOC
      },

      :use_external_subs => {
          :default    => true,
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--no-use-external-subs',
          :arg_format => nil,
          :item_label => 'Add External Subs',
          :help_group => 'Media Options',
          :help_desc  => <<~HEREDOC
                Prohibit handling of external subtitle files. Normally, valid subtitle files with the 
                same name as the movie will be added to inspections. Valid files are in the SRT format
                and either do not include a language extension (which will be treated as
                #{C.bold('--undefined-language')}), or include a language extension specified by
                #{C.bold('--keep-langs-subs')}.
          HEREDOC
      },

      #----------------------------
      # Transcoding Options
      #----------------------------

      :suffix => {
          :default    => '-original',
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--suffix',
          :arg_format => '<suffix>',
          :item_label => 'Original File Suffix',
          :help_group => 'Transcoding Options',
          :help_desc  => <<~HEREDOC
                When #{C.bold('--transcode')} is specified, new files will be written using the original filename
                and applicable extension, and the original file will be renamed plus this suffix. The default
                is #{C.bold('%s')}.
          HEREDOC
      },

      :undefined_language => {
          :default    => 'eng',
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--undefined-language',
          :arg_format => '<lang>',
          :item_label => 'Undefined Language is',
          :help_group => 'Transcoding Options',
          :help_desc  => <<~HEREDOC
                When #{C.bold('--transcode')} is specified, streams in the new file that have an undefined language
                identified will be set to this option's value. The default is #{C.bold('%s')}.
          HEREDOC
      },

      :fix_undefined_language => {
          :default    => true,
          :value      => nil,
          :arg_short  => '-u',
          :arg_long   => '--no-fix-undefined-language',
          :arg_format => nil,
          :item_label => 'Fix Undefined Language',
          :help_group => 'Transcoding Options',
          :help_desc  => <<~HEREDOC
                Prevent this program from fixing undefined languages assigned to streams. See #{C.bold('--undefined-language')}.
          HEREDOC
      },

      :encoder => {
        :default    => 'auto',
        :value      => nil,
        :arg_short  => nil,
        :arg_long   => '--encoder',
        :arg_format => nil,
        :item_label => 'Specify Non-default Encoder',
        :help_group => 'Transcoding Options',
        :help_desc  => <<~HEREDOC
                You can use #{C.bold('--encoder')} to specify the encoder to use when mm_tool determines that
                transcoding should take place. Use one of ENCODER_LIST, or #{C.bold('auto')}. The default is
                #{C.bold('%s')}. Note that #{C.bold('auto')} will choose #{C.bold('libx264')} or
                #{C.bold('libx265')}, depending on the value of #{C.bold('--codecs-video-preferred')}.
        HEREDOC
      },

      :reencode => {
        :default    => 'false',
        :value      => nil,
        :arg_short  => nil,
        :arg_long   => '--re-encode',
        :arg_format => nil,
        :item_label => "Re-encode the video stream, even if it wouldn't otherwise be required.",
        :help_group => 'Transcoding Options',
        :help_desc  => <<~HEREDOC
                Use #{C.bold('--re-encode')} to force re-encoding of the file, even if it isn't necessary.
                Use #{C.bold('--no-re-encode')} if you need to undo the option for subsequent input files.
        HEREDOC
      },

      #----------------------------
      # Quality Options
      #----------------------------

      :min_width => {
          :default    => '1920',
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--min-width',
          :arg_format => '<width>',
          :item_label => 'Minimum Video Width',
          :help_group => 'Quality Options',
          :help_desc  => <<~HEREDOC
                Specify the minimum width that is considered acceptable quality. The default is #{C.bold('%s')}.
          HEREDOC
      },

      :min_channels => {
          :default    => '6',
          :value      => nil,
          :arg_short  => nil,
          :arg_long   => '--min-channels',
          :arg_format => '<channels>',
          :item_label => 'Minimum Audio Channels',
          :help_group => 'Quality Options',
          :help_desc  => <<~HEREDOC
                Specify the minimum number of audio channels that are considered acceptable quality. The default is #{C.bold('%s')}.
          HEREDOC
      },
  }

end # module
