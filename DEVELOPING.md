# Developing RabbitFeed

## Prerequisites

### Ruby

RabbitFeed has been tested on Ruby v2.0.

Install the required gems with

        gem install bundler
        bundle install

### RabbitMQ running locally

        brew project
        rabbitmq-server

The management interface can be found [here](http://localhost:15672/). The default login is `guest/guest`. You can view exchanges [here](http://localhost:15672/#/exchanges) and queues [here](http://localhost:15672/#/queues).


## Running Tests

This will run the specs and the features:

    bundle exec rake

## Running the example project

After doing any dev work, it is good practice to verify you haven't broken the examples. Run the examples like this:

    ./run_example

You should see something similar to the following output:

    Starting non rails application consumer...
    /opt/boxen/rbenv/versions/2.0.0-p451/bin/ruby -S rspec ./spec/lib/non_rails_app/event_handler_spec.rb
    NonRailsApp::EventHandler - Consumed event: user_updates_beaver with payload: {"beaver_name"=>"beaver"}
    .

    Finished in 0.00349 seconds
    1 example, 0 failures

    Randomized with seed 59391

    Non rails application consumer started
    Starting rails application consumer...
    /opt/boxen/rbenv/versions/2.0.0-p451/bin/ruby -S rspec ./spec/controllers/beavers_controller_spec.rb
    ...

    Finished in 0.04397 seconds
    3 examples, 0 failures

    Randomized with seed 18883

    Rails application consumer started
    Starting rails application...
    Rails application started
    Triggering event...
    NonRailsApp::EventHandler - Consumed event: user_creates_beaver with payload: {"beaver_name"=>"02/16/15 12:31:41"}
    Event triggered
    RailsApp::EventHandler - Consumed event: application_acknowledges_event with payload: {"beaver_name"=>"02/16/15 12:31:41", "event_name"=>"user_creates_beaver"}
    Stopping non rails application consumer...
    Non rails application consumer stopped
    Stopping rails application consumer...
    Rails application consumer stopped
    Stopping rails application...
    Rails application stopped

## Performance Benchmarking

There is a script that can be run to benchmark the tool. It benchmarks three areas:

1. Producing events during HTTP requests within a rails application (using [siege](http://www.joedog.org/siege-home/))
2. Producing events directly
3. Consuming events

To run the benchmarking script

    brew project
    ./run_benchmark

As of 20140925, running the benchmark on this hardware:

    MacBook Pro Retina, Mid 2012
    Processor  2.6 GHz Intel Core i7
    Memory  8 GB 1600 MHz DDR3
    Software  OS X 10.8.5 (12F45)

Results in this output:

    Starting test of rails application...
    Starting rails application...
    -- create_table("beavers", {:force=>true})
       -> 0.0140s
    -- initialize_schema_migrations_table()
       -> 0.0196s
    Rails application started
          done.

    Transactions:            200 hits
    Availability:         100.00 %
    Elapsed time:           1.11 secs
    Data transferred:         0.16 MB
    Response time:            0.05 secs
    Transaction rate:       180.18 trans/sec
    Throughput:           0.14 MB/sec
    Concurrency:            9.37
    Successful transactions:         100
    Failed transactions:             0
    Longest transaction:          0.57
    Shortest transaction:         0.00

    Stopping rails application...
    Rails application stopped
    Rails application test complete


    Starting standalone publishing and consuming benchmark...
    Publishing 5000 events...
           user     system      total        real
       2.460000   0.310000   2.770000 (  2.779719)
    Consuming 5000 events...
           user     system      total        real
       2.380000   0.590000   2.970000 (  3.500515)
    Benchmark complete

## Connection Recovery Testing

A critical piece of RabbitFeed is the ability to recover from network connectivity problems. This means...

* When publishing, all events that are published make it to the queue
* When consuming, the consumer re-establishes its connection to the queue automatically

To simulate network connectivity problems, there is a recovery test script that can be run like this:

    brew project
    ./run_recovery_test

The script will publish and then consume 5000 mesages with the network dropping out every half-second.
