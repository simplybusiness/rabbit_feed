require 'rabbit_feed'
require 'rabbit_feed/consumer_connection'
require 'rabbit_feed/consumer'
require 'rabbit_feed/event_handler'
require 'rabbit_feed/event_routing'
require 'dsl'

module RabbitFeed
  extend self
  class RoutingError < Error; end
  attr_accessor :event_routing, :event_handler

  def event_handler_klass= event_handler_klass
    @event_handler = event_handler_klass.constantize
  end
end
