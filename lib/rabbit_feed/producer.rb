module RabbitFeed
  class Producer

    attr_reader :configuration

    def initialize
      @configuration = Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment
    end

    def publish_event name, payload
      event = Event.new configuration.application, configuration.version, name, payload
      ProducerConnection.publish event.serialize
    end
  end
end
