require 'codeclimate-test-reporter'
require 'rabbit_feed'
require 'rspec/its'
require 'timecop'
require 'timeout'

# Send data to code climate from semaphore
# Disable the warning messages
CodeClimate::TestReporter.configure do |config|
  config.logger.level = Logger::WARN
end
CodeClimate::TestReporter.start

# Get rid of deprecation warnings
I18n.enforce_available_locales = true

# Loads the shared examples
Dir['./spec/support/**/*.rb'].sort.each { |f| require f}

# Loads the step definitions
Dir.glob('spec/features/step_definitions/**/*_steps.rb') { |f| load f, true }

RSpec.configure do |config|

  config.expect_with :rspec do |expects|
    expects.syntax = [:should, :expect]
  end

  config.before do
    reset_environment
  end

  config.after do
    reset_environment
    # Ensure the consumer thread exists between tests
    kill_consumer_thread
    # Ensure that connections don't persist between tests
    close_connections
    # Clear event routing
    RabbitFeed::Consumer.event_routing = nil
    # Clear event definitions
    RabbitFeed::Producer.event_definitions = nil
  end

  RabbitFeed::TestingSupport.include_support config
end

def kill_consumer_thread
  if @consumer_thread.present?
    Thread.kill @consumer_thread
  end
end

def close_connections
  RabbitFeed::ProducerConnection.close
  RabbitFeed::ConsumerConnection.close
end

def reset_environment
  RabbitFeed.log                     = Logger.new('test.log')
  RabbitFeed.environment             = 'test'
  RabbitFeed.configuration_file_path = 'spec/fixtures/configuration.yml'
end
