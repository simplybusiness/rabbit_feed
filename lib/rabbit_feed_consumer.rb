require 'rabbit_feed'
require 'rabbit_feed/consumer_connection'
require 'rabbit_feed/consumer'
require 'rabbit_feed/dsl'
require 'rabbit_feed/event_handler'
require 'rabbit_feed/event_routing'

module RabbitFeed

  def self.event_handler_klass
    @event_handler_klass
  end

  def self.event_handler_klass= event_handler_klass
    @event_handler_klass = event_handler_klass
  end

  def self.event_routing
    @event_routing
  end

  def self.event_routing= event_routing
    @event_routing = event_routing
  end
end
