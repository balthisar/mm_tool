module MmTool

  #=============================================================================
  # The main application.
  #=============================================================================
  class ApplicationMain

    require 'mm_tool.rb'

    #------------------------------------------------------------
    # Attributes
    #------------------------------------------------------------
    attr_accessor :tempfile

    #------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------
    def initialize
      @tempfile = nil
      @defaults = MmUserDefaults.shared_user_defaults
    end

    #------------------------------------------------------------
    # Singleton accessor
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
    def output(message, command = false)
      puts message
      if @tempfile
        if command
          message = message + "\n"
        else
          message = message.lines.collect {|line| "# #{line}"}.join + "\n"
        end
        @tempfile&.write(message)
      end
    end

    #------------------------------------------------------------
    # Return the transcode file header.
    #------------------------------------------------------------
    def transcode_script_header
      <<~HEREDOC
        #!/bin/sh

        # Check this file, make any changes, and save it. Execute it directly,
        # or execute it with the sh command if it's not executable.

        set -e

      HEREDOC
    end

    #------------------------------------------------------------
    # Return the report header.
    #------------------------------------------------------------
    #noinspection RubyResolve
    def information_header
      info_table_src = TTY::Table.new
      @defaults.label_value_pairs.each {|pair| info_table_src << pair}
      info_table_src << ["Disposition Columns:", MmMovie.dispositions.join(', ')]
      info_table_src << ["Transcode File Location:", self.tempfile ? tempfile&.path : 'n/a']

      info_table = C.bold("Looking for file(s) and processing them with the following options:\n")
      info_table << info_table_src.render(:basic) do |renderer|
        a = @defaults.label_value_pairs.map {|p| p[0].length }.max + 1
        b = OutputHelper.console_width - a - 2
        renderer.alignments    = [:right, :left]
        renderer.multiline     = true
        renderer.column_widths = [a,b]
      end << "\n\n"
    end

    #------------------------------------------------------------
    # The main run loop, to be run for each file.
    #------------------------------------------------------------
    def run_loop(file_name)

      if @defaults[:ignore_files]
        MmMovieIgnoreList.shared_ignore_list.add(path: file_name)
        output("Note: added #{file_name} to the list of files to be ignored.")
      elsif @defaults[:unignore_files]
        MmMovieIgnoreList.shared_ignore_list.remove(path: file_name)
        output("Note: removed #{file_name} to the list of files to be ignored.")
      else
        @file_count[:processed] = @file_count[:processed] + 1
        movie = MmMovie.new(with_file: file_name)
        a = movie.interesting? # already interesting if low-quality, but separate quality check made for logic, below.
        b = MmMovieIgnoreList.shared_ignore_list.include?(file_name)
        c = movie.meets_minimum_quality?
        s = @defaults[:scan_type]&.to_sym

        if (s == :normal && a && !b && c) ||
            (s == :all && !b) ||
            (s == :flagged && b) ||
            (s == :quality && !c ) ||
            (s == :force)

          @file_count[:displayed] = @file_count[:displayed] + 1
          output(file_name)
          output(movie.format_table)
          output(movie.stream_table)
          output("#{movie.command_rename} ; \\", true)
          output("#{movie.command_transcode} ; \\", true)
          output(movie.command_review_post, true)
          output("\n\n", true)
        end
      end # if
    end

    #------------------------------------------------------------
    # Run the application with the given file/directory.
    #------------------------------------------------------------
    def run(file_or_dir)

      @file_count = { :processed => 0, :displayed => 0 }

      if @defaults[:transcode]
        @tempfile = Tempfile.create(['mm_tool-', '.sh'])
        @tempfile&.write(transcode_script_header)
        # @tempfile.flush
      end

      if @defaults[:info_header]
        output information_header
      end

      if File.file?(file_or_dir)

        original_scan_type = @defaults[:scan_type]
        @defaults[:scan_type] = :force
        run_loop(file_or_dir)
        @defaults[:scan_type] = original_scan_type

      elsif File.directory?(file_or_dir)

        extensions = @defaults[:container_files]&.join(',')
        Dir.chdir(file_or_dir) do
          Dir.glob("**/*.{#{extensions}}").map {|path| File.expand_path(path) }.sort.each do |file|
            run_loop(file)
          end
        end

      else
        output "Error: Execution should never have reached this point."
        exit 1
      end

      output("#{File.basename($0)} processed #{@file_count[:processed]} files and displayed data for #{@file_count[:displayed]} of them.")

    ensure
      if @tempfile
        @tempfile&.close
        # @tempfile.unlink
      end
    end # run

  end # class

end # module
