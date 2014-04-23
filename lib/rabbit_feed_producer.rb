require 'rabbit_feed'
require 'rabbit_feed/producer_connection'
require 'rabbit_feed/producer'

module RabbitFeed
  class ReturnedMessageError < Error; end

  def self.stub!
    ProducerConnection.stub(:publish)
  end

  def self.reconnect!
    ProducerConnection.reconnect!
  end
end
