require 'rabbit_feed'
require_relative 'non_rails_app/event_handler'

EventRouting do
  accept_from('rails_app') do
    event('user_creates_beaver') do |event|
      NonRailsApp::EventHandler.handle_event event
    end
    event('user_updates_beaver') do |event|
      NonRailsApp::EventHandler.handle_event event
    end
    event('user_deletes_beaver') do |event|
      NonRailsApp::EventHandler.handle_event event
    end
  end
end

EventDefinitions do
  define_event('application_acknowledges_event', version: '1.0.0') do
    defined_as do
      'An event has been acknowledged'
    end
    payload_contains do
      field('beaver_name', type: 'string', definition: 'The name of the beaver')
      field('event_name', type: 'string', definition: 'The name of the original event')
    end
  end
end
