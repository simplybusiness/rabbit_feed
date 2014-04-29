require 'rabbit_feed'
require_relative 'non_rails_app/event_handler'

EventRouting do
  accept_from(application: 'rails_app', version: '1.0.0') do
    event('beaver.created') do |event|
      NonRailsApp::EventHandler.handle_event event
    end
    event('beaver.updated') do |event|
      NonRailsApp::EventHandler.handle_event event
    end
    event('beaver.deleted') do |event|
      NonRailsApp::EventHandler.handle_event event
    end
  end
end
