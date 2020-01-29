# Setup our load paths
libdir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require "mm_tool/version"
require "mm_tool/application_main"
require "mm_tool/mm_tool_console_output_helpers"

module MmTool
  class Error < StandardError

  end
end
