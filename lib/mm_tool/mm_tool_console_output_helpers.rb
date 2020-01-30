#=============================================================================
# MmToolConsoleOutputHelpers
#  Private, self-contained methods that we will use that help in providing
#  legible output on the command line.
#=============================================================================
module MmToolConsoleOutputHelpers

  require 'pastel'
  require 'tty-screen'

  private

  @@pastel = Pastel.new(enabled: $stdout.tty? && $stderr.tty?)

  #------------------------------------------------------------
  # Property accessor, provides a short, easy interface for
  # using Pastel.
  #------------------------------------------------------------
  def c
    @@pastel
  end

  #------------------------------------------------------------
  # Return an array of argument groups for the given
  # application.
  #------------------------------------------------------------
  def argument_groups(application)
    application.options.collect { |i| i[1] }
        .collect { |i| i[:help_group] }
        .uniq
  end

  #------------------------------------------------------------
  # Given an argument value, return it in a format suitable
  # for output. In general, this means that we want to format
  # array values in the way we expect to receive them as
  # arguments on the command line.
  #------------------------------------------------------------
  def format_value(value)
    if value.instance_of?(Array)
      value.join(',')
    else
      value
    end
  end

  #------------------------------------------------------------
  # Given an application's argument, format the argument for
  # display in help output. Optionally specify the entire
  # width of the argument in order to right-pad it with spaces
  # and/or truncate it to the given width.
  #------------------------------------------------------------
  def format_argument(argument, width = 0 )
    s = argument[:arg_short] ? "#{argument[:arg_short]}," : nil
    l = argument[:arg_format] ? "#{argument[:arg_long]} #{argument[:arg_format]}" : "#{argument[:arg_long]}"
    f = " %-3s %s   " % [s, l]
    if width > 0
      "%-#{width}.#{width}s" % f
    else
      f
    end
  end

  #------------------------------------------------------------
  # Find the length of the longest argument label, including
  # all desired padding, for the provided application.
  #------------------------------------------------------------
  def longest_arg_length(application)
    application.options.collect { |i| i[1] }
        .collect { |i| format_argument(i).length }
        .max
  end

  #------------------------------------------------------------
  # Return a string: with a hanging indent of hang: and a
  # right margin of margin:.
  #------------------------------------------------------------
  def hanging_string( string:, hang: 0, margin: 78 )
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
  def print_error(message)
    width = [TTY::Screen.width, 61].max - 1
    STDERR.puts hanging_string(string: message, hang: 3, margin: width)
  end

  #------------------------------------------------------------
  # Displays an error message and exits the program.
  # ------------------------------------------------------------
  def print_error_and_exit(message)
    print_error(message)
    exit 1
  end

end # module MmToolConsoleOutputHelpers
