require_relative '../../spec_helper'

module NonRailsApp
  describe 'Event Routing' do
    let(:payload) { { 'field' => 'value' } }

    it 'routes events correctly' do
      expect(NonRailsApp::EventHandler).to receive(:handle_event) { |full_event| expect(full_event.payload).to eq(payload)}
      rabbit_feed_consumer.consume_event('user_creates_beaver', 'rails_app', payload)
    end
  end
end
