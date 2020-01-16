module MmTool

  class ApplicationMain

    def initialize
      @options = {
          :media_files => {
              :default    => %w(mp4 mkv avi 3gp flv),
              :value      => nil,
              :arg_short  => 'm',
              :arg_long   => 'media',
              :help_group => 'General',
              :help_desc  => <<-HEREDOC
Now is the time for all good men to come to the aid of their parties, but only after the quick brown fox jumps over
the lazy dog.
              HEREDOC
          },
          :skip_boring => {

          },
          :output_xml => {

          },
      }
    end

    def options
      @options
    end

    def self.sharedApplication
      unless @self
        @self = self.new
      end
      @self
    end

    #def initialize
    #  @optshash = Hash.new()
    #end
    #
    #def opts(key)
    #  @optshash[key]
    #end
    #
    #def opts=(o)
    #  @optshash = o
    #end
    #
    #def option(name, value)
    #
    #  if block_given?
    #    yield
    #  else
    #    @optshash[name] = value
    #  end
    #
    #
    #  #opts[:callback] ||= b if block_given?
    #  #opts[:desc] ||= desc
    #  #
    #  #o = Option.create(name, desc, opts)
    #  #
    #  #raise ArgumentError, "you already have an argument named '#{name}'" if @specs.member? o.name
    #  #raise ArgumentError, "long option name #{o.long.inspect} is already taken; please specify a (different) :long" if @long[o.long]
    #  #raise ArgumentError, "short option name #{o.short.inspect} is already taken; please specify a (different) :short" if @short[o.short]
    #  #@long[o.long] = o.name
    #  #@short[o.short] = o.name if o.short?
    #  #@specs[o.name] = o
    #  #@order << [:opt, o.name]
    #end

  end


end