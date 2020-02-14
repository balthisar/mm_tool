# Setup our load paths
libdir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require "mm_tool/output_helper"
require "mm_tool/user_defaults"
require "mm_tool/version"

require "mm_tool/application_main"
require "mm_tool/mm_tool_cli"

require 'mm_tool/mm_movie'
require 'mm_tool/mm_movie_stream'

require 'mm_tool/mm_movie_ignore_list'
require "mm_tool/mm_user_defaults"

module MmTool
  class Error < StandardError
  end
end
