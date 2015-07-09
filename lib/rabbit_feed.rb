require 'active_support/all'
require 'active_model'
require 'avro'
require 'bunny'
require 'connection_pool'
require 'yaml'
require_relative './dsl'
require 'rabbit_feed/version'
require 'rabbit_feed/client'
require 'rabbit_feed/configuration'
require 'rabbit_feed/connection_concern'
require 'rabbit_feed/event'
require 'rabbit_feed/consumer_connection'
require 'rabbit_feed/consumer'
require 'rabbit_feed/event_routing'
require 'rabbit_feed/producer_connection'
require 'rabbit_feed/producer'
require 'rabbit_feed/event_definitions'
require 'rabbit_feed/testing_support'
require 'rabbit_feed/version'

module RabbitFeed
  extend self
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RoutingError < Error; end
  class ReturnedMessageError < Error; end

  attr_accessor :log, :environment, :configuration_file_path, :application

  def configuration
    RabbitFeed.log                     ||= (Logger.new STDOUT)
    RabbitFeed.configuration_file_path ||= 'config/rabbit_feed.yml'
    RabbitFeed.environment             ||= ENV['RAILS_ENV'] || ENV['RACK_ENV']
    @configuration                     ||= (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment, application)
  end

  def exception_notify exception
    if defined? Airbrake
      (Airbrake.notify_or_ignore exception) if Airbrake.configuration.public?
    end
  end
end
