def EventRouting &block
  event_routing = RabbitFeed::EventRouting.new
  event_routing.instance_eval &block
  RabbitFeed::Consumer.event_routing = event_routing
end
