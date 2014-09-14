module RabbitFeed
  module Producer
    extend self

    attr_accessor :event_definitions

    def publish_event name, payload
      raise (Error.new 'Unable to publish event. No event definitions set.') unless event_definitions.present?
      event_definition = event_definitions[name] or raise (Error.new "definition for event: #{name} not found")
      timestamp        = Time.now.utc
      payload          = (enriched_payload payload, event_definition.version, name, timestamp)
      event            = Event.new event_definition.schema, payload
      ProducerConnection.publish event.serialize, (options name, timestamp)
      event
    end

    def stub!
      ProducerConnection.stub(:publish)
    end

    def reconnect!
      ProducerConnection.reconnect!
    end

    private

    def enriched_payload payload, version, name, timestamp
      payload.merge ({
              'application'    => RabbitFeed.configuration.application,
              'host'           => Socket.gethostname,
              'environment'    => RabbitFeed.environment,
              'created_at_utc' => timestamp.iso8601(6),
              'version'        => version,
              'name'           => name,
            })
    end

    def routing_key event_name
      "#{RabbitFeed.environment}.#{RabbitFeed.configuration.application}.#{event_name}"
    end

    def options event_name, timestamp
      {
        routing_key: (routing_key event_name),
        type:        event_name,
        app_id:      RabbitFeed.configuration.application,
        timestamp:   timestamp.to_i,
      }
    end
  end
end
