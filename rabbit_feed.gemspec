# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rabbit_feed/version'

Gem::Specification.new do |spec|
  spec.name          = 'rabbit_feed'
  spec.version       = RabbitFeed::VERSION
  spec.authors       = ['Simply Business']
  spec.email         = ['tech@simplybusiness.co.uk']
  spec.description   = %q{A gem providing asynchronous event publish and subscribe capabilities with RabbitMQ.}
  spec.summary       = %q{Enables your Ruby applications to perform centralized event logging with RabbitMq}
  spec.homepage      = 'https://github.com/simplybusiness/rabbit_feed'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Gem for interfacing with RabbitMq
  spec.add_dependency 'bunny', '>= 2.0.0', '< 2.1.0'
  # We use some helpers from ActiveSupport
  spec.add_dependency 'activesupport', '>= 3.2.0', '< 5.0.0'
  # We use validations from ActiveModel
  spec.add_dependency 'activemodel', '>= 3.2.0', '< 5.0.0'
  # Manages process pidfile
  spec.add_dependency 'pidfile'
  # Schema definitions and serialization for events
  spec.add_dependency 'avro', '>= 1.5.4', '< 1.8.0'

  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>=2.14.0', '< 3.3.0'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rutabaga'
  spec.add_development_dependency 'timecop'
end
