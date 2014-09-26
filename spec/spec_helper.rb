require 'rabbit_feed'
require 'timeout'
require 'codeclimate-test-reporter'

# Send data to code climate from semaphore
# Disable the warning messages
CodeClimate::TestReporter.configure do |config|
  config.logger.level = Logger::WARN
end
CodeClimate::TestReporter.start

# Get rid of deprecation warnings
I18n.enforce_available_locales = true

# Loads the step definitions
Dir.glob('spec/features/step_definitions/**/*_steps.rb') { |f| load f, true }

# Dummy airbrake config
Airbrake.configure do |config|
  config.api_key = 'blah'
end

RSpec.configure do |config|

  config.before do
    reset_environment
  end

  config.after do
    reset_environment
    # Delete the test exchange we create
    delete_exchange
    # Delete the test queue we create
    delete_queue
    # Ensure that connections don't persist between tests
    close_connections
    # Clear event routing
    RabbitFeed::Consumer.event_routing = nil
    # Clear event definitions
    RabbitFeed::Producer.event_definitions = nil
  end

  config.include(RabbitFeed::TestingSupport::RSpecMatchers)
end

def delete_exchange
  RabbitFeed::ProducerConnection.open do |connection|
    connection.send(:exchange).delete
  end if @exchange.present?
end

def delete_queue
  RabbitFeed::ConsumerConnection.open do |connection|
    while (connection.connection.queue_exists? @queue) do
      connection.send(:queue).delete
    end
  end if @queue.present?
end

def close_connections
  RabbitFeed::Connection.reconnect!
  RabbitFeed::ProducerConnection.reconnect!
  RabbitFeed::ConsumerConnection.reconnect!
end

def reset_environment
  RabbitFeed.log = Logger.new('test.log')
  RabbitFeed.environment = 'test'
  RabbitFeed.configuration_file_path = 'spec/fixtures/configuration.yml'
end
