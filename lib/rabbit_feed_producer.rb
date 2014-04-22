require 'rabbit_feed'
require 'rabbit_feed/producer_connection'
require 'rabbit_feed/producer'

module RabbitFeed
  class ReturnedMessageError < Error; end
end
