require 'spec_helper'

step 'I create a connection' do
  RabbitFeed::Connection.open { |connection| @connection = connection }
end

step 'the connection is open' do
  expect(@connection.open?).to be_true
end

step 'I close the connection' do
  @connection.close
end

step 'the connection is closed' do
  expect(@connection.open?).to be_false
end

step 'I declare a new exchange' do
  @exchange = 'rabbit_feed_'+SecureRandom.uuid
  allow_any_instance_of(RabbitFeed::Configuration).to receive(:exchange).and_return(@exchange)
end

step 'the exchange is created' do
  exchange_name.should eq @exchange
  exchange_exists?.should be_true
end

step 'I can publish a message to the exchange' do
  @message_text = 'test_message_'+Time.now.to_f.to_s
  RabbitFeed::Producer.publish_event 'test', @message_text
end

step 'I declare a new queue' do
  @queue = 'rabbit_feed_'+SecureRandom.uuid
  allow_any_instance_of(RabbitFeed::Configuration).to receive(:queue).and_return(@queue)
end

step 'the queue is created' do
  queue_name.should eq @queue
  queue_exists?.should be_true
end

step 'the queue is bound to the exchange' do; end

step 'I can consume a message from the queue' do
  message_count.should eq 0
  send 'I can publish a message to the exchange'
  consume_message.should eq @message_text
  message_count.should eq 0
end

step 'I am unable to successfully process a message' do
  send 'I declare a new queue'
  message_count.should eq 0
  send 'I can publish a message to the exchange'
  actual_text = consume_message do |message|
    raise 'Could not process this message: '+message
  end
  actual_text.should eq @message_text
end

step 'the message remains on the queue' do
  RabbitFeed::ConsumerConnection.reconnect! # Don't let the existing connection keep a monopoly on the message
  message_count.should eq 1
  consume_message.should eq @message_text
end

module Turnip::Steps

  class TestEventHandler

    attr_reader :action, :event

    def initialize &block
      @action = block
    end

    def handle_event event
      @event = event
      yield action
    end
  end

  def consume_message &block
    event_handler = TestEventHandler.new &block
    allow(RabbitFeed::Consumer).to receive(:event_handler).and_return(event_handler)
    begin
      Timeout::timeout(0.5) do
        RabbitFeed::Consumer.start
      end
    rescue Timeout::Error
    end
    event_handler.event.payload
  end

  def message_count
    RabbitFeed::ConsumerConnection.open do |connection|
      return connection.send(:queue).message_count
    end
  end

  def queue_name
    RabbitFeed::ConsumerConnection.open do |connection|
      return connection.send(:queue).name
    end
  end

  def exchange_name
    RabbitFeed::ProducerConnection.open do |connection|
      return connection.send(:exchange).name
    end
  end

  def queue_exists?
    RabbitFeed::Connection.open do |connection|
      return connection.connection.queue_exists? @queue
    end
  end

  def exchange_exists?
    RabbitFeed::Connection.open do |connection|
      return connection.connection.exchange_exists? @exchange
    end
  end

  def last_message
    RabbitFeed::ConsumerConnection.open do |connection|
      return connection.send(:queue).pop.try(:last)
    end
  end
end
