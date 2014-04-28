require 'rabbit_feed'
require 'rabbit_feed/producer_connection'
require 'rabbit_feed/producer'

module RabbitFeed
  extend self
  class ReturnedMessageError < Error; end

  def stub!
    ProducerConnection.stub(:publish)
  end

  def reconnect!
    ProducerConnection.reconnect!
  end
end
