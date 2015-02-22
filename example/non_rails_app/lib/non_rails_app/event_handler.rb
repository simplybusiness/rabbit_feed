module NonRailsApp
  module EventHandler
    extend self

    def handle_event event
      puts "NonRailsApp::EventHandler - Consumed event: #{event.metadata[:name]} with payload: #{event.payload}"
      RabbitFeed::Producer.publish_event 'application_acknowledges_event', ({ 'event_name' => event.metadata[:name] }.merge event.payload)
    end
  end
end
