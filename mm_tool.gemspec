# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mm_tool/version"

Gem::Specification.new do |spec|
  spec.name        = 'mm_tool'
  spec.version     = MmTool::VERSION
  spec.authors     = ['Jim Derry']
  spec.email       = ['balthisar@gmail.com']

  spec.summary     = 'Build complete macOS application help books using Middleman.'
  spec.description = 'Build complete macOS application help books using Middleman.'
  spec.homepage    = 'https://github.com/middlemac/middlemac'
  spec.license     = 'MIT'

  spec.platform    = Gem::Platform::RUBY


  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/balthisar/mm_tool"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end


  # Specify which files should be added to the gem when it is released.
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  spec.bindir        = 'bin'
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ['lib']


  # Additional dependencies
  spec.add_runtime_dependency 'tty'
  spec.add_runtime_dependency 'streamio-ffmpeg'

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'git'
end
