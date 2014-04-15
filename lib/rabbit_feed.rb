require 'active_support/all'
require 'active_model'
require 'airbrake'
require 'connection_pool'
require 'rabbit_feed/version'
require 'rabbit_feed/configuration'
require 'rabbit_feed/connection'

module RabbitFeed
  class Error < StandardError; end
  class ConfigurationError < Error; end

  def self.log
    @log
  end

  def self.log= log
    @log = log
  end
end
