require 'rabbit_feed'
require 'rabbit_feed/consumer_connection'
require 'rabbit_feed/consumer'
require 'rabbit_feed/event_handler'

module RabbitFeed

  def self.event_handler_klass
    @event_handler_klass
  end

  def self.event_handler_klass= event_handler_klass
    @event_handler_klass = event_handler_klass
  end
end
