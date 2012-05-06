# -*- mode: ruby; coding: utf-8 -*-

require File.expand_path('../lib/ruote-nats/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors     = ['Naoto Takai']
  gem.email       = ['takai@recompile.net']
  gem.description = 'NATS participant and receivers for ruote'
  gem.summary     = 'ruote-nats is an implementation of the ruote participant and receivers ' \
                    'to process workitem on remote host using NATS'
  gem.homepage    = 'https://github.com/takai/ruote-nats'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'ruote-nats'
  gem.require_paths = ['lib']
  gem.version       = RuoteNATS::VERSION

  gem.add_dependency('ruote', '= 2.2.0')
  gem.add_dependency('nats', '>= 0.4.22')
  gem.add_dependency('msgpack', '>= 0.4.6')

  gem.add_development_dependency('rspec')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('simplecov')
  gem.add_development_dependency('pry')
  gem.add_development_dependency('pry-nav')
  gem.add_development_dependency('yard')
  gem.add_development_dependency('redcarpet')
  gem.add_development_dependency('github-markup')
end
