lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'archfiend/version'

Gem::Specification.new do |spec|
  spec.name          = 'archfiend'
  spec.version       = Archfiend::VERSION
  spec.authors       = ['Maciek Dubiński']
  spec.email         = ['maciek@dubinski.net']

  spec.summary       = 'A tool to simplify creation and development of Ruby daemons'
  spec.description   = 'A tool to simplify creation and development of Ruby daemons.'
  spec.homepage      = 'https://github.com/toptal/archfiend'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'activerecord', '~> 5' # For specs
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'config', '~> 2.0'
  spec.add_dependency 'oj', '~> 3.6'
  spec.add_development_dependency 'pg', '~> 1.1'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.72'
  spec.add_development_dependency 'rubocop-rails', '~> 2.2'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.33'
  spec.add_development_dependency 'simplecov', '~> 0.18'
  spec.add_dependency 'thor', '~> 0.20' # CLI
end
