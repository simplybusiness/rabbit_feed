require 'active_support/all'
require 'active_model'
require 'airbrake'
require 'bunny'
require 'connection_pool'
require 'yaml'
require 'rabbit_feed/version'
require 'rabbit_feed/client'
require 'rabbit_feed/configuration'
require 'rabbit_feed/connection'
require 'rabbit_feed/event'

module RabbitFeed
  extend self
  class Error < StandardError; end
  class ConfigurationError < Error; end

  attr_accessor :log, :environment, :configuration_file_path

  def configuration
    @configuration ||= (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment)
  end
end
