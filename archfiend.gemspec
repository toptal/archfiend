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

  spec.add_dependency 'activesupport' # CLI
  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'config'
  spec.add_dependency 'oj'
  spec.add_development_dependency 'pg', '~> 0.21'
  spec.add_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_dependency 'thor' # CLI
end
