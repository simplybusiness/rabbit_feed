module RabbitFeed
  class EventHandler

    def handle_event event
      puts "#{event.name}: #{event.payload}"
    end
  end
end
