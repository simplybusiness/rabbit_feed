def EventRouting &block
  event_routing = RabbitFeed::EventRouting.new
  event_routing.instance_eval &block
  RabbitFeed::Consumer.event_routing = event_routing
end

def EventDefinitions &block
  event_definitions = RabbitFeed::EventDefinitions.new
  event_definitions.instance_eval &block
  RabbitFeed::Producer.event_definitions = event_definitions
end
