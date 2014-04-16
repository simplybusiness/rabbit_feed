require 'rabbit_feed_producer'
require 'rabbit_feed_consumer'

# Get rid of deprecation warnings
I18n.enforce_available_locales = true

# Set up the test environment
RabbitFeed.log = Logger.new('test.log')
RabbitFeed.environment = 'test'
RabbitFeed.configuration_file_path = 'spec/fixtures/configuration.yml'
