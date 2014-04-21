module RabbitFeed
  class Consumer

    def start
      ConsumerConnection.consume do |message|
        RabbitFeed.message_handler_klass.constantize.new.handle_message message
      end
    end
  end
end
