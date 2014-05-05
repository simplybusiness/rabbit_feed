require 'non_rails_app'

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.before :each do
    RabbitFeed::Producer.stub!
  end

  RSpec::configure do |config|
    config.include(RabbitFeed::RSpecMatchers)
  end
end

RabbitFeed.log = Logger.new('test.log')
RabbitFeed.environment = 'test'
RabbitFeed.configuration_file_path = 'config/rabbit_feed.yml'
