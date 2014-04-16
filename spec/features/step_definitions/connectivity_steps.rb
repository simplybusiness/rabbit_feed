require 'spec_helper'

step 'I create a connection' do
  RabbitFeed::Connection.open { |connection| @connection = connection }
end

step 'I create a producer connection' do
  RabbitFeed::ProducerConnection.open { |connection| @connection = connection }
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

step 'I can publish a message' do
  @connection.publish 'message'
end
