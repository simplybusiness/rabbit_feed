module RailsApp
  describe 'Event Routing' do

    it 'routes events correctly' do
      expect do
        rabbit_feed_consumer.consume_event(RabbitFeed::Event.new({'application' => 'non_rails_app', 'name' => 'application_acknowledges_event'}))
      end.to output("RailsApp::EventHandler - Consumed event: application_acknowledges_event with payload: {}\n").to_stdout
    end
  end
end
