module NonRailsApp
  class EventHandler < RabbitFeed::EventHandler

    def handle_event name, payload
      puts "NonRailsApp::EventHandler - Consumed event: #{name} with payload: #{payload}"
      RabbitFeed::Producer.publish_event 'event.processed', { event_name: name, original_payload: payload }
    end
  end
end
