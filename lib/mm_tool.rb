# Setup our load paths
libdir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require "mm_tool/version"
require "mm_tool/application_main"

module MmTool
  class Error < StandardError

  end
end
