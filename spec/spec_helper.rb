require 'simplecov'
SimpleCov.start

require 'rabbit_feed'
require 'rspec/its'
require 'timecop'
require 'timeout'

# Get rid of deprecation warnings
I18n.enforce_available_locales = true

# Loads the shared examples
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

# Loads the step definitions
Dir.glob('spec/features/step_definitions/**/*_steps.rb') { |f| load f, true }

RSpec.configure do |config|
  config.expect_with :rspec do |expects|
    expects.syntax = %i[should expect]
  end

  config.before do
    reset_environment
  end

  config.after(connectivity: true) do
    @consumer_thread.kill if @consumer_thread.present?
    @consumer_thread.join if @consumer_thread.present?
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
