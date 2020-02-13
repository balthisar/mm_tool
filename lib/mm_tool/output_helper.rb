module MmTool

  require 'pastel'

  #------------------------------------------------------------
  # Constants to help with output
  #------------------------------------------------------------
  C = Pastel.new(enabled: $stdout.tty? && $stderr.tty?)

  class OutputHelper

    #------------------------------------------------------------
    # Return a string: with a hanging indent of hang: and a
    # right margin of margin:.
    #------------------------------------------------------------
    def self.hanging_string( string:, hang: 0, margin: 78 )
      indent_spaces = " " * hang
      result = []

      # Each individual paragraph should end with two newlines; therefore convert
      # individual newlines into spaces, and break the paragraphs into a split.
      string.gsub(/\n\n/, "\f").gsub(/\n/, " ").split(/\f/).each do |line|

        buffer = ''
        line.split(/\s/).each do |word|

          word = ' ' if word.length == 0

          len_buffer = buffer.gsub(/\e\[([;\d]+)?m/, '').length

          if len_buffer == 0 || buffer[-1] == ' '
            added_word = word
          else
            added_word = ' ' + word
          end

          len_word = added_word.gsub(/\e\[([;\d]+)?m/, '').length

          width = result.count == 0 ? margin : margin - hang

          if len_buffer + len_word <= width
            buffer = buffer + added_word
          else
            if result.count == 0
              result << buffer + "\n"
            else
              result << indent_spaces + buffer + "\n"
            end
            buffer = word
          end

        end # line

        if result.count == 0
          result << buffer + "\n\n"
        else
          result << indent_spaces + buffer + "\n\n"
        end

      end

      result.join[0...-1]
    end

    #------------------------------------------------------------
    # Displays an error message and returns from subroutine.
    # ------------------------------------------------------------
    def self.print_error(message)
      width = [TTY::Screen.width, 61].max - 1
      STDERR.puts self.hanging_string(string: message, hang: 3, margin: width)
    end

    #------------------------------------------------------------
    # Displays an error message and exits the program.
    # ------------------------------------------------------------
    def self.print_error_and_exit(message)
      self.print_error(message)
      exit 1
    end

    #------------------------------------------------------------
    # Gather the basic dimensions required for output. We'll
    # support a minimum width of 60, which is reasonable for any
    # modern console, and allows enough room for fairly long
    # argument examples. If STDOUT is not to a console, then
    # adjust to 80 columns.
    # ------------------------------------------------------------
    def self.console_width
      $stdout.tty? ? [TTY::Screen.width, 60].max : 80
    end

  end # class

  #------------------------------------------------------------
  # Output bool as YES/NO/NOTHING
  # ------------------------------------------------------------
  class ::TrueClass
    def human
      "YES"
    end
  end

  #------------------------------------------------------------
  # Output bool as YES/NO/NOTHING
  # ------------------------------------------------------------
  class ::FalseClass
    def human
      "NO"
    end
  end

  #------------------------------------------------------------
  # Output bool as YES/NO/NOTHING
  # ------------------------------------------------------------
  class ::NilClass
    def human
      "NOTHING"
    end
  end

end # module
