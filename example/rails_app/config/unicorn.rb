worker_processes Integer(4)
timeout 15
preload_app true
pid File.join('tmp', 'pids', 'unicorn.pid')

after_fork do |server, worker|
  require 'rabbit_feed'
  RabbitFeed::Producer.reconnect!
end
