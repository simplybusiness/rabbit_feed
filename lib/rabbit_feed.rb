require 'active_support/all'
require 'active_model'
require 'avro'
require 'bunny'
require 'yaml'
require_relative './dsl'
require 'rabbit_feed/version'
require 'rabbit_feed/client'
require 'rabbit_feed/configuration'
require 'rabbit_feed/event'
require 'rabbit_feed/connection'
require 'rabbit_feed/consumer_connection'
require 'rabbit_feed/consumer'
require 'rabbit_feed/event_routing'
require 'rabbit_feed/producer_connection'
require 'rabbit_feed/producer'
require 'rabbit_feed/event_definitions'
require 'rabbit_feed/testing_support'
require 'rabbit_feed/version'
require 'rabbit_feed/json_log_formatter'

module RabbitFeed
  extend self
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RoutingError < Error; end
  class ReturnedMessageError < Error; end

  attr_accessor :log, :environment, :configuration_file_path, :application

  def configuration
    @configuration ||= (Configuration.load configuration_file_path, environment, application)
  end

  def exception_notify(exception)
    return unless defined?(Airbrake)
    if RabbitFeed.configuration.consumer_exit_after_fail
      # Will need to send the notification right away, otherwise the `exit` would kill the
      # Airbrake before the notification is sent out
      Airbrake.notify_sync exception
    else
      # Airbrake notify default to sending notification asynchronously
      Airbrake.notify exception
    end
  end

  def default_logger
    if File.directory? 'log'
      Logger.new 'log/rabbit_feed.log', 10, 100.megabytes
    else
      Logger.new STDOUT
    end.tap do |log|
      log.formatter = RabbitFeed::JsonLogFormatter
      log.level     = Logger::INFO
    end
  end

  def set_defaults
    self.log                     ||= default_logger
    self.configuration_file_path ||= 'config/rabbit_feed.yml'
    self.environment             ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
  end
  private :set_defaults

  set_defaults
end
