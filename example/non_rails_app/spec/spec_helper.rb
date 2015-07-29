require 'non_rails_app'

RSpec.configure do |config|
  RabbitFeed::TestingSupport.setup(config)
end
