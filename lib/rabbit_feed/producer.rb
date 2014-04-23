module RabbitFeed
  class Producer

    def self.publish_event name, payload
      event = Event.new RabbitFeed.configuration.application, RabbitFeed.configuration.version, name, payload
      ProducerConnection.publish event.serialize, event.routing_key
      event
    end
  end
end
