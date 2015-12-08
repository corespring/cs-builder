# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cs-builder/version', __FILE__)

name = "cs-builder-two"

Gem::Specification.new do |gem|
  gem.authors       = ["edeustace"]
  gem.email         = ["edeustace@gmail.com"]
  gem.description   = %q{The corespring build and deploy tool}
  gem.summary       = gem.description
  gem.homepage      = "http://github.com/ecorespring/cs-builder"
  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = name
  gem.require_paths = ["lib"]
  gem.required_ruby_version = '>= 2.0.0'
  gem.version       = CsBuilder::VERSION
  gem.add_development_dependency "rspec", "~> 2.6"
  gem.add_development_dependency "rake", "~> 10.1.0"
  gem.add_development_dependency "dotenv", "~> 0.11.1"
  gem.add_dependency "thor"
  gem.add_dependency "log4r", '~> 1.1.10'
  gem.add_dependency "rest-client", '~> 1.6.7'

end
