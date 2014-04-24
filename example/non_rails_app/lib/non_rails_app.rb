require 'rabbit_feed_consumer'
require 'rabbit_feed_producer'
require_relative 'non_rails_app/event_handler'

EventRouting do
  accept_from(application: 'rails_app', version: '1.0.0') do
    event('beaver.created')
    event('beaver.updated')
    event('beaver.deleted')
  end
end
