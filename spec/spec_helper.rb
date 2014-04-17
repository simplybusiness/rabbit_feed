require 'rabbit_feed_producer'
require 'rabbit_feed_consumer'

# Get rid of deprecation warnings
I18n.enforce_available_locales = true

# Set up the test environment
RabbitFeed.log = Logger.new('test.log')
RabbitFeed.environment = 'test'
RabbitFeed.configuration_file_path = 'spec/fixtures/configuration.yml'

# Loads the step definitions
Dir.glob('spec/features/step_definitions/**/*_steps.rb') { |f| load f, true }

RSpec.configure do |config|
  config.after do
    # Delete any test exchanges we create
    if @connection && @exchange
      @connection.send(:exchange).try(:delete)
    end
    # Ensure that connections don't persist between tests
    RabbitFeed::Connection.reconnect!
    RabbitFeed::ProducerConnection.reconnect!
  end
end
