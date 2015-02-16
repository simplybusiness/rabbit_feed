module RabbitFeed
  module Producer
    extend self

    attr_accessor :event_definitions

    def publish_event name, payload
      raise (Error.new 'Unable to publish event. No event definitions set.') unless event_definitions.present?
      event_definition   = event_definitions[name] or raise (Error.new "definition for event: #{name} not found")
      publishing_options = PublishingOptions.new name, Time.now.utc, event_definition.version
      event              = Event.new event_definition.schema, payload, publishing_options.metadata
      ProducerConnection.publish event.serialize, publishing_options.to_h
      event
    end
  end
end
