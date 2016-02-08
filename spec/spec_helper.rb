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

  config.after(connectivity: true) do
    Thread.kill @consumer_thread if @consumer_thread.present?
  end

  RabbitFeed::TestingSupport.include_support config
end

def reset_environment
  RabbitFeed.log                         = RabbitFeed.default_logger
  RabbitFeed.application                 = nil
  RabbitFeed.environment                 = 'test'
  RabbitFeed.configuration_file_path     = 'spec/fixtures/configuration.yml'
  RabbitFeed.instance_variable_set('@configuration', nil)
  RabbitFeed::Consumer.event_routing     = nil
  RabbitFeed::Producer.event_definitions = nil
end
