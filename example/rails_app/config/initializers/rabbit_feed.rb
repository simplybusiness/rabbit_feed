require 'rabbit_feed_producer'

RabbitFeed.log                     = Logger.new(Rails.root.join('log/rabbit_feed.log'))
RabbitFeed.environment             = Rails.env
RabbitFeed.configuration_file_path = File.join(Rails.root, 'config/rabbit_feed.yml')

require 'rabbit_feed_consumer'

EventRouting do
  accept_from(application: 'non_rails_app', version: '1.0.0') do
    event('event.processed')
  end
end

