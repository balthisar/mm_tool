module MmTool

  #=============================================================================
  # A single user default.
  #=============================================================================
  class MmUserDefault

    #------------------------------------------------------------
    # Attributes
    #------------------------------------------------------------
    attr_reader :name
    attr_reader :default
    attr_reader :arg_short
    attr_reader :arg_long
    attr_reader :arg_format
    attr_reader :item_label
    attr_reader :help_group
    attr_reader :help_desc

    #------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------
    def initialize(key:, value:)
      @name       = key
      @value      = value[:value]
      @default    = value[:default]
      @arg_short  = value[:arg_short]
      @arg_long   = value[:arg_long]
      @arg_format = value[:arg_format]
      @item_label = value[:item_label]
      @help_group = value[:help_group]
      @help_desc  = value[:help_desc]
      @value_set = false
    end

    #------------------------------------------------------------
    # Value attribute accessors.
    #------------------------------------------------------------
    def value
      if value_set?
        @value
      else
        @default
      end
    end

    def value=(value)
      @value = value
      @value_set = true
    end

    def value_printable
      if self.value.instance_of?(Array)
        self.value.join(',')
      elsif [TrueClass, FalseClass].include?(self.value.class)
        self.value.human
      else
        self.value
      end
    end

    #------------------------------------------------------------
    # Indicates whether or not a value has been set.
    #------------------------------------------------------------
    def value_set?
      @value_set
    end

    #------------------------------------------------------------
    # Utility: get an argument for output, aligning the short
    #  and long forms.
    #------------------------------------------------------------
    def example_arg
      s = self.arg_short ? "#{self.arg_short}," : nil
      l = self.arg_format ? "#{self.arg_long} #{self.arg_format}" : "#{self.arg_long}"
      # " %-3s %s   " % [s, l]
      "%-3s %s" % [s, l]
    end

  end # class


  #=============================================================================
  # Handles application user defaults as a singleton. This is specific to
  # MmTool, and is not meant to be a general purpose User Defaults system.
  #=============================================================================
  class MmUserDefaults

    require 'tty-table'

    #------------------------------------------------------------
    # Singleton accessor.
    #------------------------------------------------------------
    def self.shared_user_defaults
      unless @self
        @self = self.new
      end
      @self
    end

    #------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------
    def initialize
      @defaults = {}
    end

    #------------------------------------------------------------
    # The location on the filesystem where the file exists.
    #------------------------------------------------------------
    def file_path
      PATH_USER_DEFAULTS
    end


    #------------------------------------------------------------
    # Creates a new user default object and add it to the
    # collection.
    #------------------------------------------------------------
    def define_default(for_key:, value:)
      @defaults[for_key] = MmUserDefault.new(key:for_key,value:value)
    end

    #------------------------------------------------------------
    # Sets up initial defaults from a large hash indicating all
    # of the user defaults and attributes for the default.
    # Also sets up the persistence system. If the file doesn't
    # exist, it will be created with the current key-value
    # pairs. If it does exist, existing key-value pairs will
    # be reconciled with current key-value pairs. Finally,
    # values from the file will be applied.
    #------------------------------------------------------------
    def register_defaults(with_hash:)

      # *Define* each of the possible defaults. These will have
      # default values. We're actually kind of good to go at
      # this point if we don't want to use the rc file.

      with_hash.each {|k,v| define_default(for_key:k, value:v) }

      # If the file doesn't exist, create it and add our current
      # key-value pairs to it. Otherwise, read the file, compare
      # it to our current set of key-value pairs, and make
      # adjustments, re-writing the file if necessary.

      if !File.file?(file_path)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.open(file_path, 'w') { |file| file.write(hash_representation.to_yaml) }
      else
        #noinspection RubyResolve
        #@type [Hash] working
        working = YAML.load(File.read(file_path))
        new = working.select {|k,_| hash_representation.has_key?(k)} # only keeps working items if they are current.
        new = new.merge(hash_representation.select {|k,_| !new.has_key?(k)}) # select the new items.
        File.open(file_path, 'w') { |file| file.write(new.to_yaml) } unless working == new
        new.each {|k,v| self[k] = v }
      end
    end

    #------------------------------------------------------------
    # Returns all default instances as an array.
    #------------------------------------------------------------
    def all_defaults
      @defaults.values.sort_by(&:name)
    end

    #------------------------------------------------------------
    # Returns all default instances as a hash, with key and
    # value only. If there's no item label, assume that the
    # default is a command and not an actual setting, and
    # skip it.
    #------------------------------------------------------------
    def hash_representation
      all_defaults.select {|d| d.item_label}
          .collect { |d| [d.name, d.value] }.to_h
    end

    #------------------------------------------------------------
    # Get a single default instance.
    #------------------------------------------------------------
    def default(key)
      @defaults[key]
    end

    #------------------------------------------------------------
    # Return the value of a setting by key or nil.
    #------------------------------------------------------------
    def [](key)
      result = default(key)
      result ? result.value : nil
    end

    #------------------------------------------------------------
    # Set the value of a setting by key.
    #------------------------------------------------------------
    def []=(key, value)
      if default(key)
        default(key).value = value
      else
        define_default(for_key:key, value:value)
      end
    end

    #------------------------------------------------------------
    # Get and set defaults via methods.
    #------------------------------------------------------------
    def method_missing(method, *args)
      if defines_default?(method) && args.empty?
        self[method]
      elsif method.to_s =~ /^(\w+)=$/ && args.size == 1
        self[Regexp.last_match(1).to_sym] = args[0]
      else
        super
      end
    end

    #------------------------------------------------------------
    # Ensure that we account for our dynamic methods.
    #------------------------------------------------------------
    def respond_to?(method, include_private = false)
      super || defines_default?(method) || (method =~ /^(\w+)=$/ && defines_default?(Regexp.last_match(1)))
    end

    #------------------------------------------------------------
    # Does the default exist?
    #------------------------------------------------------------
    def defines_default?(key)
      @defaults.key?(key)
    end

    #------------------------------------------------------------
    # Utility: get all of the argument help text by group, into
    #   a simple hash with group names as keys.
    #------------------------------------------------------------
    def arguments_help_by_group

      table = {}

      argument_groups.each do |group|

        #noinspection RubyResolve
        key = "\n#{C.bold(group)}\n\n"
        table[key] = []

        @defaults.values.select { |default| default.help_group == group }
            .each do |default|
          width = example_args_by_length[-1].length
          arg = " %-#{width}.#{width}s   " % default.example_arg
          des = default.help_desc % default.value
          table[key] << arg + des
        end
      end
      table
    end

    #------------------------------------------------------------
    # Utility: get an array of argument examples, sorted by
    #   length.
    #------------------------------------------------------------
    def example_args_by_length
      @defaults.values
          .sort {|a,b| a.example_arg.length <=> b.example_arg.length}
          .collect {|d| d.example_arg}
    end

    #------------------------------------------------------------
    # Utility: Return an array of argument groups. They will
    #   be in the order that they were added to user defaults.
    #------------------------------------------------------------
    def argument_groups
      @defaults.values
          .collect {|default| default.help_group}
          .uniq
    end

    #------------------------------------------------------------
    # Returns an array of labels and the current matching value.
    # Accepts a block to add your own pairs.
    #------------------------------------------------------------
    def label_value_pairs
      result = @defaults.values.select {|default| default.item_label}
                        .map {|default| ["#{default.item_label}:", default.value_printable]}
      yield result if block_given?
      result
    end


  end # class

end # module
