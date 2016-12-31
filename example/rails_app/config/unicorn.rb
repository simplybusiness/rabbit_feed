worker_processes Integer(1)
timeout 15
preload_app true
pid File.join('tmp', 'pids', 'unicorn.pid')
