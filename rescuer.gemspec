$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'rescuer/version'

Gem::Specification.new do |s|
  s.name        = 'rescuer'
  s.version     = Rescuer::VERSION
  s.author      = 'Marc Siegel'
  s.email       = 'msiegel@usainnov.com'
  s.homepage    = 'http://ms-ati.github.com/rescuer/'
  s.summary     = 'Rescuer rescues the composability of exception-raising code blocks'
  s.description = 'Rescuer is a functional abstraction of exception handling inspired by Scala\'s Try class'
  s.license     = 'MIT'

  s.rubyforge_project = 'rescuer'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  # Running rspec tests from rake
  s.add_development_dependency 'rake',  '~> 10.3.0'
  s.add_development_dependency 'rspec', '3.0.0.beta2'

  if !(defined?(RUBY_ENGINE) && 'jruby' == RUBY_ENGINE)
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency 'yard'
    s.add_development_dependency 'redcarpet'
    s.add_development_dependency 'github-markup'
  end

  # Coveralls test coverage tool
  s.add_development_dependency 'coveralls'
end