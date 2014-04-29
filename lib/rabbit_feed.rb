require 'active_support/all'
require 'active_model'
require 'airbrake'
require 'bunny'
require 'connection_pool'
require 'yaml'
require 'dsl'
Dir[File.join(File.dirname(__FILE__), 'rabbit_feed', '*.rb')].each {|file| require file }

module RabbitFeed
  extend self
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RoutingError < Error; end
  class ReturnedMessageError < Error; end

  attr_accessor :log, :environment, :configuration_file_path

  def configuration
    @configuration ||= (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment)
  end
end
