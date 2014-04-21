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
      consumer = RabbitFeed::Consumer.new
      consumer.start
    end

    def produce
      producer = RabbitFeed::Producer.new
      producer.publish_event 'Manual publish', options.first
    end
  end
end
