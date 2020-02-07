module MmTool

  #=============================================================================
  # The main application.
  #=============================================================================
  class ApplicationMain

    require 'mm_tool/mm_tool_console_output_helpers'
    require 'mm_tool/mm_movie'
    require 'mm_tool/mm_movie_ignore_list'
    include MmToolConsoleOutputHelpers

    #------------------------------------------------------------
    # Attributes
    #------------------------------------------------------------
    attr_accessor :tempfile
    attr_accessor :options

    #------------------------------------------------------------
    # Define and setup module level variables.
    #------------------------------------------------------------
    def initialize

      #noinspection RubyResolve
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
                A comma-separated list of file extensions assumed to be media files. The default is #{c.bold('%s')}.
              HEREDOC
          },

          :scan_type => {
              :default    => 'normal',
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--scan',
              :arg_format => '<scan_type>',
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Type of files for which to show result. #{c.bold('normal')} will display results of files that have
                some change proposed to them, or have some other characteristic that merits review. #{c.bold('all')}
                will display all media files, even if there's nothing interesting about them (however, ignore-flagged
                files will be ignored. #{c.bold('flagged')} will show data for all ignore-flagged files.
                #{c.bold('quality')} will show results only for files not meeting quality thresholds.
                The default is #{c.bold('%s')}.
              HEREDOC
          },

          :info_header => {
              :default    => true,
              :value      => nil,
              :arg_short  => '-i',
              :arg_long   => '--no-info-header',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Don't show the information header indicating much of the configuration at the beginning of the output.
              HEREDOC
          },

          :ignore_files => {
              :default    => false,
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--ignore-files',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Files following this command will not be inspected; instead, they will be added to the persistent list
                of files to be ignored. You can use #{c.bold('--no-ignore-files')} to flip this flag back off for
                subsequent files on the command line.
              HEREDOC
          },

          :unignore_files => {
              :default    => false,
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--unignore-files',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Files following this command will be removed from the persistent list of files to be ignored. 
                You can use #{c.bold('--no-unignore-files')} to flip this flag back off for subsequent files on the 
                command line.
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

          :dump => {
              :default    => false,
              :value      => nil,
              :arg_short  => '-p',
              :arg_long   => '--dump',
              :arg_format => nil,
              :help_group => 'Main Options',
              :help_desc  => <<~HEREDOC
                Show the raw file information for the media file instead of the summary table. This implies
                #{c.bold('--no-transcode')}.
              HEREDOC
          },

          :stop_processing => {
              :default    => false,
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
                is not one of these types, then it will be reported. If #{c.bold('--transcode')} is specified, and
                a file is a non-preferred container, then it will be transcoded to the #{c.underline('first')} item
                in this list. The default is #{c.bold('%s')}.
              HEREDOC
          },

          :codecs_audio_preferred => {
              :default    => %w(aac ac3 eac3),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--codec-audio-preferred',
              :arg_format => '<codecs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{c.bold('--transcode')} is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{c.underline('first')} item in this list. The default
                is #{c.bold('%s')}.
              HEREDOC
          },

          :codecs_video_preferred => {
              :default    => %w(hevc h265 h264),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--codec-video-preferred',
              :arg_format => '<codecs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{c.bold('--transcode')}  is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{c.underline('first')} item in this list. The default
                is #{c.bold('%s')}.
              HEREDOC
          },

          :codecs_subs_preferred => {
              :default    => %w(subrip mov_text),
              :value      => nil,
              :arg_short  => nil,
              :arg_long   => '--codec-subs-preferred',
              :arg_format => '<codecs>',
              :help_group => 'Media Options',
              :help_desc  => <<~HEREDOC
                A comma-separated list of preferred audio codecs. Streams of this codec will not be transcoded.
                If #{c.bold('--transcode')}  is specified, and the codec of the stream is not on this list, then
                the stream will be transcoded to the #{c.underline('first')} item in this list. The default
                is #{c.bold('%s')}.
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
                #{c.bold('--transcode')} is specified, audio streams with languages that are not on this list
                will be discarded unless it is the only stream. Use the special language code  #{c.bold('und')}
                to ensure that streams without a designated language are not discarded! The default is #{c.bold('%s')}.
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
                #{c.bold('--transcode')} is specified, video streams with languages that are not on this list
                will be discarded unless it is the only stream. Use the special language code  #{c.bold('und')}
                to ensure that streams without a designated language are not discarded! The default is #{c.bold('%s')}.
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
                #{c.bold('--transcode')} is specified, subtitles of languages that are not on this list
                will be discarded. Use the special language code  #{c.bold('und')} to ensure that streams
                without a designated language are not discarded! The default is #{c.bold('%s')}.
                See also #{c.bold('--codec-subs-preferred')}, whose condition is AND with this condition
                (both must be true to pass through the subtitle).
              HEREDOC
          },

          #----------------------------
          # Transcoding Options
          #----------------------------

          :transcode => {
              :default    => false,
              :value      => nil,
              :arg_short  => '-t',
              :arg_long   => '--transcode',
              :arg_format => nil,
              :help_group => 'Transcoding Options',
              :help_desc  => <<~HEREDOC
                Write transcoding instructions. Containers and streams that are not in preferred formats will be
                transcoded; streams that are not in the preferred language will be dropped, unless they are the
                only video or only audio stream. Transcoding instructions will be written to a random file.
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
                When #{c.bold('--transcode')} is specified, new files will be written using the original filename
                and applicable extension, and the original file will be renamed plus this suffix. The default
                is #{c.bold('%s')}.
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
                When #{c.bold('--transcode')} is specified, streams in the new file that have an undefined language
                identified will be set to this option's value. The default is #{c.bold('%s')}.
              HEREDOC
          },

          :fix_undefined_language => {
              :default    => true,
              :value      => nil,
              :arg_short  => '-u',
              :arg_long   => '--no-fix-undefined-language',
              :arg_format => nil,
              :help_group => 'Transcoding Options',
              :help_desc  => <<~HEREDOC
                Prevent this program from fixing undefined languages assigned to streams. See #{c.bold('--undefined-language')}.
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
              :help_group => 'Quality Options',
              :help_desc  => <<~HEREDOC
                Specify the minimum width that is considered acceptable quality. The default is #{c.bold('%s')}.
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
                Specify the minimum number of audio channels that are considered acceptable quality. The default is #{c.bold('%s')}.
              HEREDOC
          },
      }
    end # initialize

    #------------------------------------------------------------
    # Get the value of a setting by key.
    #------------------------------------------------------------
    def [](key)
      if @options.key?(key)
        @options[key][:value] ? @options[key][:value] : @options[key][:default]
      else
        nil
      end
    end

    #------------------------------------------------------------
    # Set the value of a setting by key.
    #------------------------------------------------------------
    def []=(key, val)
      if @options.key?(key)
        @options[key][:value] = val
      else
        raise "Error: setting “#{key}” doesn't exist."
      end
    end

    #------------------------------------------------------------
    # Singleton accessor.
    #------------------------------------------------------------
    def self.shared_application
      unless @self
        @self = self.new
      end
      @self
    end

    #------------------------------------------------------------
    # Output a message to the screen, and if applicable, to
    # the temporary file for later opening.
    #------------------------------------------------------------
    def output(message)
      puts message
    end

    #------------------------------------------------------------
    # Return the transcode file header.
    #------------------------------------------------------------
    def transcode_script_header
      <<~HEREDOC
        #!/bin/sh

        # Check this file, make any changes, and save it. It will be executed as soon
        # as you close it. By default, this script will exit per the exit command
        # below. Please further confirm that you wish to proceed with the proposed
        # actions by commenting or removing the line below.
        
        exit 1

      HEREDOC
    end

    #------------------------------------------------------------
    # Return the report header.
    #------------------------------------------------------------
    #noinspection RubyResolve
    def information_header
      <<~HEREDOC
                #{c.bold('Looking for file(s) and processing them with the following options:')}
                           Media Filetypes: #{self[:container_files]&.join(',')}
                                 Scan Type: #{self[:scan_type]}
                                  Raw Dump: #{self[:dump]&.human}
                      Preferred Containers: #{self[:containers_preferred]&.join(',')}
                    Preferred Audio Codecs: #{self[:codecs_audio_preferred]&.join(',')}
                    Preferred Video Codecs: #{self[:codecs_video_preferred]&.join(',')}
                 Preferred Subtitle Codecs: #{self[:codecs_subs_preferred]&.join(',')}
                      Keep Audio Languages: #{self[:keep_langs_audio]&.join(',')}
                      Keep Video Languages: #{self[:keep_langs_audio]&.join(',')}
                   Keep Subtitle Languages: #{self[:keep_langs_audio]&.join(',')}
                       Transcode if Needed: #{self[:transcode]&.human}
                   Transcode file Location: #{self.tempfile ? tempfile.path : 'n/a'}
                      Original File Suffix: #{self[:suffix]}
                     Undefined Language is: #{self[:undefined_language]} 
                    Fix Undefined Language: #{self[:fix_undefined_language]&.human}
                       Minimum Video Width: #{self[:min_width]}
                    Minimum Audio Channels: #{self[:min_channels]}
        #{hanging_string(string: '               Disposition Columns: ' + MmMovie.dispositions.join(', '), hang: 36, margin: TTY::Screen.width - 1) }
      HEREDOC
    end

    #------------------------------------------------------------
    # The main run loop, to be run for each file.
    #------------------------------------------------------------
    def run_loop(file_name)

      if self[:ignore_files]
        MmMovieIgnoreList.shared_ignore_list.add(path: file_name)
        output("Note: added #{file_name} to the list of files to be ignored.")
      elsif self[:unignore_files]
        MmMovieIgnoreList.shared_ignore_list.remove(path: file_name)
        output("Note: removed #{file_name} to the list of files to be ignored.")
      else
        unless MmMovieIgnoreList.shared_ignore_list.include?(file_name)
          movie = MmMovie.new(with_file: file_name, owner:self)
          output movie.path
          output "   Title: #{movie.format_title}"
          output "Duration: #{movie.format_duration}"
          output "    Size: #{movie.format_size}"
          if self[:dump]
            pp(movie.ff_movie)
          else
            output(movie.table_text)
            output movie.command_transcode
            puts
          end
        end

      end # if
    end


    #------------------------------------------------------------
    # Run the application with the given file/directory.
    #------------------------------------------------------------
    def run(file_or_dir)

      if self[:transcode]
        self.tempfile = Tempfile.new('mm_tool-')
      end

      if self[:info_header]
        output information_header
      end

      if File.file?(file_or_dir)

        # verbose = self[:verbose]
        # self[:verbose] = true
        run_loop(file_or_dir)
        # self[:verbose] = verbose

      elsif File.directory?(file_or_dir)

        extensions = self[:container_files]&.join(',')
        Dir.chdir(file_or_dir) do
          Dir.glob("**/*.{#{extensions}}").map {|path| File.expand_path(path) }.sort.each do |file|
            run_loop(file)
          end
        end

      else
        output "Error: Execution should never have reached this point."
        exit 1
      end

    ensure
      if self.tempfile
        self.tempfile.unlink
      end

    end # run

  end # class ApplicationMain

end # module MmTool
