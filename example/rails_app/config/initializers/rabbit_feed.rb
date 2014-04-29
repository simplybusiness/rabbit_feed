require 'rabbit_feed'

RabbitFeed.log                     = Logger.new(Rails.root.join('log/rabbit_feed.log'))
RabbitFeed.environment             = Rails.env
RabbitFeed.configuration_file_path = File.join(Rails.root, 'config/rabbit_feed.yml')

EventRouting do
  accept_from(application: 'non_rails_app', version: '1.0.0') do
    event('event.processed') do |event|
      ::EventHandler.handle_event event
    end
  end
end
