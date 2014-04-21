module RabbitFeed
  class Producer

    def publish payload
      ProducerConnection.publish payload
    end
  end
end
