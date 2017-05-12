# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rabbit_feed/version'

Gem::Specification.new do |spec|
  spec.name          = 'rabbit_feed'
  spec.version       = RabbitFeed::VERSION
  spec.authors       = ['Simply Business']
  spec.email         = ['tech@simplybusiness.co.uk']
  spec.description   = 'A gem providing asynchronous event publish and subscribe capabilities with RabbitMQ.'
  spec.summary       = 'Enables your Ruby applications to perform centralized event logging with RabbitMq'
  spec.homepage      = 'https://github.com/simplybusiness/rabbit_feed'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Gem for interfacing with RabbitMq
  spec.add_dependency 'bunny', '>= 2.0.0', '< 2.7.0'
  # We use some helpers from ActiveSupport
  spec.add_dependency 'activesupport', '>= 3.2.0', '< 6.0.0'
  # We use validations from ActiveModel
  spec.add_dependency 'activemodel', '>= 3.2.0', '< 6.0.0'
  # Manages process pidfile
  spec.add_dependency 'pidfile', '~> 0.3'
  # Schema definitions and serialization for events
  spec.add_dependency 'avro', '>= 1.5.4', '< 1.9.0'

  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
  spec.add_development_dependency 'rubocop', '~> 0.46'
  spec.add_development_dependency 'rutabaga', '~> 2.1'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'timecop', '~> 0.8'
end
