module RabbitFeed
  module Producer
    extend self

    attr_accessor :event_definitions

    def publish_event name, payload
      event_definition = event_definitions[name] or raise (Error.new "definition for event: #{name} not found")
      event = Event.new event_definition.schema, (enriched_payload payload, event_definition.version)
      ProducerConnection.publish event.serialize, (routing_key name)
      event
    end

    def stub!
      ProducerConnection.stub(:publish)
    end

    def reconnect!
      ProducerConnection.reconnect!
    end

    private

    def enriched_payload payload, version
      payload.merge ({
              'application'    => RabbitFeed.configuration.application,
              'host'           => Socket.gethostname,
              'environment'    => RabbitFeed.environment,
              'created_at_utc' => Time.now.utc.to_f,
              'version'        => version,
            })
    end

    def routing_key event_name
      "#{RabbitFeed.environment}.#{RabbitFeed.configuration.application}.#{event_name}"
    end
  end
end
