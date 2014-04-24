class EventHandler < RabbitFeed::EventHandler

  def handle_event name, payload
    puts "RailsApp::EventHandler - Consumed event: #{name} with payload: #{payload}"
  end
end
