module RabbitFeed
  class EventHandler

    def handle_event name, payload
      puts "#{name}: #{payload}"
    end
  end
end
