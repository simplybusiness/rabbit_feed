module RabbitFeed
  class Consumer

    def start
      ConsumerConnection.consume do |event|
        RabbitFeed.event_handler_klass.constantize.new.handle_event event
      end
    end
  end
end
