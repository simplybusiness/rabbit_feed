module EventHandler
  extend self

  def handle_event event
    puts "RailsApp::EventHandler - Consumed event: #{event.name} with payload: #{event.payload}"
  end
end
