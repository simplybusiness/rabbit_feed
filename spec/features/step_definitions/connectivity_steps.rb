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

step 'I can publish an event to the exchange' do
  @event_text = 'test_event_'+Time.now.to_f.to_s
  RabbitFeed::Producer.publish_event 'test', @event_text
end

step 'I declare a new queue' do
  @queue = 'rabbit_feed_'+SecureRandom.uuid
  allow_any_instance_of(RabbitFeed::Configuration).to receive(:queue).and_return(@queue)

  EventRouting do
    accept_from(application: 'rabbit_feed', version: '1.0.0') do
      event('test') {|event|}
    end
  end
end

step 'the queue is created' do
  queue_name.should eq @queue
  queue_exists?.should be_true
end

step 'the queue is bound to the exchange' do; end

step 'I can consume an event from the queue' do
  event_count.should eq 0
  send 'I can publish an event to the exchange'
  consume_event.should eq @event_text
  event_count.should eq 0
end

step 'I am unable to successfully process an event' do
  send 'I declare a new queue'
  event_count.should eq 0
  send 'I can publish an event to the exchange'
  actual_text = consume_event do |event|
    raise 'Could not process this event: '+event
  end
  actual_text.should eq @event_text
end

step 'the event remains on the queue' do
  RabbitFeed::ConsumerConnection.reconnect! # Don't let the existing connection keep a monopoly on the event
  event_count.should eq 1
  consume_event.should eq @event_text
end

module Turnip::Steps

  def consume_event &block
    handled_event = nil
    EventRouting do
      accept_from(application: 'rabbit_feed', version: '1.0.0') do
        event('test') do |event|
          handled_event = event
          (block.call event.payload) if block.present?
        end
      end
    end

    begin
      Timeout::timeout(0.5) do
        RabbitFeed::Consumer.start
      end
    rescue Timeout::Error
    end
    handled_event.payload if handled_event.present?
  end

  def event_count
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

  def last_event
    RabbitFeed::ConsumerConnection.open do |connection|
      return connection.send(:queue).pop.try(:last)
    end
  end
end
