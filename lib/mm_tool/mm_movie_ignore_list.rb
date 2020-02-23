module MmTool

  #=============================================================================
  # A list of movie files to ignore during :normal and :all scan types. Will
  # keep the on-file list in sync with the in-memory list.
  #=============================================================================
  class MmMovieIgnoreList

    require 'fileutils'
    require 'yaml'

    #------------------------------------------------------------
    # Singleton accessor.
    #------------------------------------------------------------
    def self.shared_ignore_list
      unless @self
        @self = self.new
      end
      @self
    end

    #------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------
    def initialize
      @ignore_list = []
      if !File.file?(file_path)
        FileUtils.mkdir_p(File.dirname(file_path))
      else
        #noinspection RubyResolve
        @ignore_list = YAML.load(File.read(file_path))
      end
    end

    #------------------------------------------------------------
    # The location on the filesystem where the file exists.
    #------------------------------------------------------------
    def file_path
      PATH_IGNORE_LIST
    end

    #------------------------------------------------------------
    # Is the given file on the ignore list?
    #------------------------------------------------------------
    def include?(path)
      @ignore_list.include?(path)
    end

    #------------------------------------------------------------
    # Add a path to the list, and write list to disk.
    #------------------------------------------------------------
    def add(path:)
      new_list = @ignore_list |= [path]
      @ignore_list = new_list.sort
      File.open(file_path, 'w') { |file| file.write(@ignore_list.to_yaml(options = {:line_width => -1})) }
    end

    #------------------------------------------------------------
    # Remove a path from the list, and update on disk.
    #------------------------------------------------------------
    def remove(path:)
      @ignore_list.delete(path)
      File.open(file_path, 'w') { |file| file.write(@ignore_list.to_yaml(options = {:line_width => -1})) }
    end

  end # class

end # module
