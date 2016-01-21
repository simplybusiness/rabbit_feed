module RabbitFeed
  module Producer
    extend self

    attr_accessor :event_definitions

    def publish_event name, payload
      raise (Error.new 'Unable to publish event. No event definitions set.') unless event_definitions.present?
      event_definition = event_definitions[name] or raise (Error.new "definition for event: #{name} not found")
      timestamp        = Time.now.utc
      metadata         = (metadata event_definition.version, name, timestamp)
      event            = Event.new metadata, payload, event_definition.schema, event_definition.sensitive_fields
      RabbitFeed.log.info {{ event: :publish_start, metadata: event.metadata }}
      ProducerConnection.instance.publish event.serialize, (options name, timestamp)
      RabbitFeed.log.info {{ event: :publish_end, metadata: event.metadata }}
      event
    end

    private

    def metadata version, name, timestamp
      {
        'application'    => RabbitFeed.configuration.application,
        'host'           => Socket.gethostname,
        'environment'    => RabbitFeed.environment,
        'created_at_utc' => timestamp.iso8601(6),
        'version'        => version,
        'name'           => name,
        'schema_version' => Event::SCHEMA_VERSION,
      }
    end

    def routing_key event_name
      "#{RabbitFeed.environment}#{RabbitFeed.configuration.route_prefix_extension}.#{RabbitFeed.configuration.application}.#{event_name}"
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
