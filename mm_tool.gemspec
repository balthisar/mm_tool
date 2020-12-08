# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mm_tool/version"

Gem::Specification.new do |spec|
  spec.name        = 'mm_tool'
  spec.version     = MmTool::VERSION
  spec.authors     = ['Jim Derry']
  spec.email       = ['balthisar@gmail.com']

  spec.summary     = 'Curate your movie files.'
  spec.description = 'A tool for curating your movie files.'
  spec.homepage    = 'https://github.com/balthisar/mm_tool'
  spec.license     = 'MIT'

  spec.platform    = Gem::Platform::RUBY


  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = 'https://rubygems.org'

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/balthisar/mm_tool"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end


  # Specify which files should be added to the gem when it is released.
  spec.files         = `git ls-files`.split("\n").reject { |f| f == 'bin/setup' || f == 'bin/console'}
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  spec.bindir        = 'bin'
  spec.executables   = `git ls-files -- bin/*`.split("\n").reject { |f| f == 'bin/setup' || f == 'bin/console'}.map{ |f| File.basename(f) }
  spec.require_paths = ['lib']


  # Additional dependencies
  spec.add_runtime_dependency 'tty', "~>0.10"
  spec.add_runtime_dependency 'streamio-ffmpeg'
  spec.add_runtime_dependency 'bytesize'
  spec.add_runtime_dependency 'natural_sort', "0.3.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.17.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'git'
end
