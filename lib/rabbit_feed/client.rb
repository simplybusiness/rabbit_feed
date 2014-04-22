module RabbitFeed
  class Client

    attr_reader :command, :options

    def initialize command, options
      @command = command
      @options = options
    end

    def run
      send(command)
    end

    private

    def consume
      RabbitFeed::Consumer.start
    end

    def produce
      RabbitFeed::Producer.publish_event 'Manual publish', options.first
    end
  end
end
