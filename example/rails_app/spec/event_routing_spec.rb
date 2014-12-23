require_relative 'rails_helper'

module RailsApp
  describe 'Event Routing' do
    let(:event) { {'application' => 'non_rails_app', 'name' => 'application_acknowledges_event'} }

    it 'routes events correctly' do
      expect(::EventHandler).to receive(:handle_event)
      rabbit_feed_consumer.consume_event(event)
    end
  end
end
