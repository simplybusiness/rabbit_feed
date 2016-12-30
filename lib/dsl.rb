def EventRouting(&block)
  RabbitFeed::Consumer.event_routing ||= RabbitFeed::EventRouting.new
  RabbitFeed::Consumer.event_routing.instance_eval(&block)
end

def EventDefinitions(&block)
  RabbitFeed::Producer.event_definitions ||= RabbitFeed::EventDefinitions.new
  RabbitFeed::Producer.event_definitions.instance_eval(&block)
end
