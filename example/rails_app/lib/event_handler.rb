module EventHandler
  extend self

  def handle_event event
    puts "RailsApp::EventHandler - Consumed event: #{event.metadata[:name]} with payload: #{event.payload}"
  end
end
