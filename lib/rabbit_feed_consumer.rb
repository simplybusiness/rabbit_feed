require 'rabbit_feed'
require 'rabbit_feed/consumer_connection'
require 'rabbit_feed/consumer'
require 'rabbit_feed/message_handler'

module RabbitFeed

  def self.message_handler_klass
    @message_handler_klass
  end

  def self.message_handler_klass= message_handler_klass
    @message_handler_klass = message_handler_klass
  end
end
