require_relative 'rails_helper'

module RailsApp
  describe 'Event Routing' do
    let(:payload) { {'field' => 'value'} }

    it 'routes events correctly' do
      expect(::EventHandler).to receive(:handle_event)
      rabbit_feed_consumer.consume_event('application_acknowledges_event', 'non_rails_app', payload)
    end
  end
end
