module NonRailsApp
  module EventHandler
    extend self

    def handle_event event
      puts "NonRailsApp::EventHandler - Consumed event: #{event.name} with payload: #{event.payload}"
      RabbitFeed::Producer.publish_event 'event.processed', { event_name: event.name, original_payload: event.payload }
    end
  end
end
