module NonRailsApp
  describe 'Event Routing' do
    let(:payload)  { { 'field' => 'value' } }
    let(:metadata) { { 'application' => 'rails_app', 'name' => 'user_creates_beaver' } }
    let(:event)    { RabbitFeed::Event.new metadata, payload }

    it 'routes events correctly' do
      expect(NonRailsApp::EventHandler).to receive(:handle_event) { |full_event| expect(full_event.payload).to eq(payload) }
      rabbit_feed_consumer.consume_event(event)
    end
  end
end
