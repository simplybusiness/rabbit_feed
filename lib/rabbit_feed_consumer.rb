require 'rabbit_feed'
require 'rabbit_feed/consumer_connection'
require 'rabbit_feed/consumer'
require 'rabbit_feed/event_handler'
require 'rabbit_feed/event_routing'
require 'dsl'

module RabbitFeed

  class << self
    attr_accessor :event_routing, :event_handler
  end

  def self.event_handler_klass= event_handler_klass
    @event_handler = event_handler_klass.constantize
  end
end
