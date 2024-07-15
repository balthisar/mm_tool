module MmTool

  #=============================================================================
  # Implement the command line interface for MmTool::ApplicationMain
  #=============================================================================
  class MmToolCli

    require 'tty-command'
    require 'tty-which'

    #------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------
    def initialize(app_instance = MmTool::ApplicationMain.shared_application)
      self.validate_prerequisites

      decorated_list = MmTool.encoder_list.map{|s| C.bold(s)}.join(', ')
      USER_DEFAULTS[:encoder][:help_desc].gsub!('ENCODER_LIST', decorated_list)

      @application = app_instance
      @defaults = MmUserDefaults.shared_user_defaults
      @defaults.register_defaults(with_hash: USER_DEFAULTS)
    end

    #------------------------------------------------------------
    # Print Help
    #------------------------------------------------------------
    #noinspection RubyResolve
    def print_help
      # Amount of hanging indent is dependent on the space arguments take up.
      hang = @defaults.example_args_by_length[-1].length + 4

      header = <<~HEREDOC
        #{C.bold('Usage:')} #{File.basename($0)} [options...] <directory|file> [options...] <directory|file> ...
        
        Performs media analysis and reports on files that don't meet quality requirements and/or files that
        have containers and/or streams of undesired types. Files with undesired containers and/or streams
        can optionally be transcoded into a new file.
        
        You must specify a file or a directory. Specifying a directory implies a recursive search for files
        matching the #{C.bold('--container-extension')} option.
  
        Options and files are processed as they occur, and remain in effect for subsequent input files until
        encountered again with a different value. Boolean flags shown below modify default behavior. They
        can be undone for subsequent input files with the capitalized version of the short flag, or by adding
        or deleting #{C.bold('no-')} for the verbose argument form.

        You can also set default options in #{PATH_USER_DEFAULTS}.
      HEREDOC

      puts OutputHelper.hanging_string(string: header, hang: 3, margin: OutputHelper.console_width)

      @defaults.arguments_help_by_group.each_pair do |group, arguments|
        puts group
        arguments.each do |argument|
          puts OutputHelper.hanging_string(string: argument, hang: hang, margin: OutputHelper.console_width) + "\n"
        end
      end
    end

    #------------------------------------------------------------
    # Validate pre-requisites.
    #------------------------------------------------------------
    #noinspection RubyResolve
    def validate_prerequisites
      commands        = %w(ffmpeg ffprobe)
      codecs_required = %w(libx264 libx265 libfdk_aac)
      task            = TTY::Command.new(printer: :null)
      success         = true

      # We'll check everything in items before failing, so that we can provide
      # a comprehensive list to the user. No one wants to see what's missing
      # on-by-one.
      commands.each do |command|
        unless TTY::Which.exist?(command)
          OutputHelper.print_error("Error: #{C.bold(command)} is not installed (or not in your #{C.bold('$PATH')}).")
          success = false
        end
      end
      exit 1 unless success

      # Now we'll make sure that all of the required codecs are installed as part of ffmpeg.
      # This is necessary because not every binary distribution supports non-free.

      # Again, we'll check them all before failing in order to list everything.
      codecs_required.each do |codec|
        result = task.run!("ffprobe -v quiet -codecs | grep #{codec}")
        OutputHelper.print_error("Error: ffmpeg was built without support for the #{C.bold(codec)} codec, which is required.") if result.failure?
        success = success && result.success?
      end
      exit 1 unless success

    end

    #------------------------------------------------------------
    # Run the CLI.
    #------------------------------------------------------------
    #noinspection RubyResolve
    def run(args)

      path = nil
      while args.count > 0 do

        # Convert single hyphen arguments to one or more multi-hyphen
        # arguments. Doing this as an extra step eliminates redundancy,
        # but also allows -abc in place of -a -b -c.
        if args[0] =~ /^-[A-Za-z]+$/

          args[0][1..-1].reverse.each_char do |char|

            case char

            when 'h'
              args.insert(1, '--help')
            when 'i'
              args.insert(1, '--no-info-header')
            when 'I'
              args.insert(1, '--info-header')
            when 's'
              args.insert(1, '--no-shell-commands')
            when 'S'
              args.insert(1, '--shell-commands')
            when 't'
              args.insert(1, '--transcode')
            when 'T'
              args.insert(1, '-no-transcode')
            when 'u'
              args.insert(1, '--no-fix-undefined-language')
            when 'U'
              args.insert(1, '--fix-undefined-language')
            when 'p'
              args.insert(1, '--dump')
            when 'P'
              args.insert(1, '--no-dump')
            else
              OutputHelper.print_error_and_exit("Error: option #{C.bold(args[0])} was specified, but I don't know what that means.")
            end

          end

          args.shift
          next
        end

        # The main loop processes options, commands, and files in first-in,
        # first out order, which is the normal Unix way compared to how
        # Ruby scripts try to handle things.
        case args[0]

          #-----------------------
          # Main Options
          #-----------------------

        when '--help'
          self.print_help
          exit 0

        when '--containers'
          @defaults[:container_files] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--scan'
          value = validate_arg_value(args[0], args[1]).downcase
          unless %w(normal all flagged quality force).include?(value)
            OutputHelper.print_error("Note: value #{C.bold(value)} doesn't make sense; assuming #{C.bold('normal')}.")
            value = 'normal'
          end
          @defaults[:scan_type] = value
          args.shift

        when '--ignore-titles'
          @defaults[:ignore_titles] = true

        when '--no-ignore-titles'
          @defaults[:ignore_titles] = false

        when '--no-info-header'
          @defaults[:info_header] = false

        when '--info-header'
          @defaults[:info_header] = true

        when '--no-shell-commands'
          @defaults[:shell_commands] = false

        when '--shell-commands'
          @defaults[:shell_commands] = true

        when '--version'
          puts "#{File.basename $0}, version #{MmTool::VERSION}"
          exit 0

        when '--'
          break

          #-----------------------
          # Command-like Options
          #-----------------------

        when '--transcode'
          @defaults[:ignore_files] = false
          @defaults[:unignore_files] = false
          @defaults[:transcode] = true

        when '--no-transcode'
          @defaults[:transcode] = false
          @application.tempfile = nil

        when '--ignore-files'
          @defaults[:ignore_files] = true

        when '--no-ignore-files'
          @defaults[:ignore_files] = false

        when '--unignore-files'
          @defaults[:unignore_files] = true

        when '--no-unignore-files'
          @defaults[:unignore_files] = false


          #-----------------------
          # Media
          #-----------------------

        when '--containers-preferred'
          @defaults[:containers_preferred] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--codecs-audio-preferred'
          @defaults[:codec_audio_preferred] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--codecs-video-preferred'
          @defaults[:codec_video_preferred] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--codecs-subs-preferred'
          @defaults[:codec_subs_preferred] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--keep-langs-audio'
          @defaults[:keep_langs_audio] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--keep_langs_video'
          @defaults[:keep_langs_video] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--keep-langs-subs'
          @defaults[:keep_langs_subs] = validate_arg_value(args[0], args[1]).split(',')
          args.shift

        when '--no-use-external-subs'
          @defaults[:use_external_subs] = false

        when '--use-external-subs'
          @defaults[:use_external_subs] = true

          #-----------------------
          # Transcoding
          #-----------------------

        when '--no-drop-subs'
          @defaults[:drop_subs] = false

        when '--suffix'
          @defaults[:suffix] = validate_arg_value(args[0], args[1])

        when '--undefined-language'
          @defaults[:suffix] = validate_arg_value(args[0], args[1])

        when '--no-fix-undefined-language'
          @defaults[:fix_undefined_language] = false

        when '--fix-undefined-language'
          @defaults[:fix_undefined_language] = true

        when '--encoder'
          @defaults[:encoder] = validate_encoder_value(args[0], args[1])

        when '--re-encode'
          @defaults[:reencode] = true

        when '--no-re-encode'
          @defaults[:reencode] = false

          #-----------------------
          # Quality
          #-----------------------

        when '--min-width'
          @defaults[:min_width] = validate_arg_value(args[0], args[1])

        when '--min-channels'
          @defaults[:min_channels] = validate_arg_value(args[0], args[1])

          #-----------------------
          # Other
          #-----------------------

        else

          # An unknown parameter was encountered, so let's stop everything.
          if args[0] =~ /^--.*$/
            OutputHelper.print_error_and_exit("Error: option #{C.bold(args[0])} was specified, but I don't know what that means.")
          end

          # Otherwise, check for existence of the path, and proceed or warn.
          path = File.expand_path(args[0])
          if File.exist?(path)
            @application.run(path)
          else
            OutputHelper.print_error("Note: skipping #{C.bold(path)}, which seems not to exist.")
          end

        end # case

        args.shift

      end # while

      # If path has never been set, then the user didn't specify anything to check,
      # which is likely to be a mistake.
      unless path
        OutputHelper.print_error_and_exit("You did not specify any input file(s) or directory(s). Use #{C.bold(File.basename($0))} for help.")
      end

    end

    #------------------------------------------------------------
    # Perform a really simple validation of the given value for
    # the given argument, returning the value if successful.
    # ------------------------------------------------------------
    #noinspection RubyResolve
    def validate_arg_value(arg, value)
      if !value
        OutputHelper.print_error_and_exit("Error: option #{C.bold(arg)} was specified, but no value was given.")
      elsif value =~ /^-.*$/
        OutputHelper.print_error_and_exit("Error: option #{C.bold(arg)} was specified, but the value #{C.bold(value)} looks like another option argument.")
      end
      value
    end

    #------------------------------------------------------------
    # Perform a really simple validation of the given value for
    # the given argument, returning the value if successful.
    # ------------------------------------------------------------
    #noinspection RubyResolve
    def validate_encoder_value(arg, value)
      if !value
        OutputHelper.print_error_and_exit("Error: option #{C.bold(arg)} was specified, but no value was given.")
      elsif value =~ /^-.*$/
        OutputHelper.print_error_and_exit("Error: option #{C.bold(arg)} was specified, but the value #{C.bold(value)} looks like another option argument.")
      end
      unless MmTool.encoder_list.include?(value)
        OutputHelper.print_error_and_exit("Error: Unknown encoder #{C.bold(value)} specified for option #{C.bold(arg)}. Use #{C.bold(File.basename($0) << '--help')} for supported encoders.")
      end
      value
    end

  end # class

end # module
