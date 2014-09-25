require_relative '../../spec_helper'

module NonRailsApp
  describe 'Event Routing' do

    include RabbitFeed::TestingSupport::TestingHelpers

    let(:event) { {'application' => 'rails_app', 'name' => 'user_creates_beaver'} }
    it 'routes events correctly' do
      expect(NonRailsApp::EventHandler).to receive(:handle_event).with { |full_event| expect(full_event.payload).to eq(event)}
      rabbit_feed_consumer.consume_event(event)
    end
  end
end
