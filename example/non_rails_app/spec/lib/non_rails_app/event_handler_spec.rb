module NonRailsApp
  describe EventHandler do

    describe '#handle_event' do
      it 'publishes an update event' do
        expect{
          described_class.handle_event RabbitFeed::Event.new({'name' => 'user_updates_beaver', 'application' => 'rails_app'}, {'beaver_name' => 'beaver'})
        }.to publish_event('application_acknowledges_event', { 'beaver_name' => 'beaver', 'event_name' => 'user_updates_beaver' })
      end
    end
  end
end
