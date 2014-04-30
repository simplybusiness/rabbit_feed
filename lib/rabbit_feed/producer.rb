module RabbitFeed
  module Producer
    extend self

    attr_accessor :event_definitions

    def publish_event name, payload
      event = Event.new RabbitFeed.configuration.application, RabbitFeed.configuration.version, name, payload
      ProducerConnection.publish event.serialize, event.routing_key
      event
    end

    def stub!
      ProducerConnection.stub(:publish)
    end

    def reconnect!
      ProducerConnection.reconnect!
    end
  end
end
