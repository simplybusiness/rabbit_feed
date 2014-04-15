# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rabbit_feed/version'

Gem::Specification.new do |spec|
  spec.name          = 'rabbit_feed'
  spec.version       = RabbitFeed::VERSION
  spec.authors       = ['Simply Business']
  spec.email         = ['tech@simplybusiness.co.uk']
  spec.description   = %q{A gem allowing your application to publish messages to RabbitMQ}
  spec.summary       = %q{This will enable your application to publish messages to a bus to be processed by other services}
  spec.homepage      = 'https://github.com/simplybusiness/rabbit_feed'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Gem for interfacing with RabbitMq
  spec.add_dependency 'bunny'
  # We use some helpers from ActiveSupport
  spec.add_dependency 'activesupport'
  # We use validations from ActiveModel
  spec.add_dependency 'activemodel'
  # Provides connection pooling for the producer connections
  spec.add_dependency 'connection_pool'
  # Error reporting mechanism (used by producer and consumer)
  spec.add_dependency 'airbrake'
end
