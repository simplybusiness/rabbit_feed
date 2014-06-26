# RabbitFeed

![RabbitFeed logo](https://cloud.githubusercontent.com/assets/768254/3286432/b4e65e7e-f548-11e3-9c91-f7d04f489cf3.png)

A gem providing asynchronous event publish and subscribe capabilities with RabbitMQ.

## Core concepts

* Fire and forget: Application can publish an event and it has no knowledge/care of how that event is consumed.
* Persistent events: Once an event has been published, it will persist until it has been processed successfully.
* Event order preserved: Events are received in the order they were generated.
* Multiple subscribers: Multiple applications can subscribe to the same events.
* Event versioning: Consumers can customize event handling based on the event version.

## Developing

### Requirements

1. RabbitMQ running locally

        brew project
        rabbitmq-server

The management interface can be found [here](http://localhost:15672/). The default login is `guest/guest`. You can view exchanges [here](http://localhost:15672/#/exchanges) and queues [here](http://localhost:15672/#/queues).

### Running Tests

This will run the specs and the features:

    bundle exec rake

### Running the example project

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
    NonRailsApp::EventHandler - Consumed event: user_creates_beaver with payload: {"application"=>"rails_app", "host"=>"macjfleck.home", "environment"=>"development", "version"=>"1.0.0", "name"=>"user_creates_beaver", "created_at_utc"=>"2014-05-05T14:16:44.045395Z", "beaver_name"=>"05/05/14 15:16:43"}
    Event triggered
    RailsApp::EventHandler - Consumed event: application_acknowledges_event with payload: {"application"=>"non_rails_app", "host"=>"macjfleck.home", "environment"=>"development", "version"=>"1.0.0", "name"=>"application_acknowledges_event", "created_at_utc"=>"2014-05-05T14:16:44.057279Z", "beaver_name"=>"05/05/14 15:16:43", "event_name"=>"user_creates_beaver"}
    Stopping non rails application consumer...
    Non rails application consumer stopped
    Stopping rails application consumer...
    Rails application consumer stopped
    Stopping rails application...
    Rails application stopped

### Performance Benchmarking

There is a script that can be run to benchmark the tool. It benchmarks three areas:

1. Producing events during HTTP requests within a rails application (using [siege](http://www.joedog.org/siege-home/))
2. Producing events directly
3. Consuming events

To run the benchmarking script

    brew project
    ./run_benchmark

As of 20140506, running the benchmark on this hardware:

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
    Elapsed time:           0.65 secs
    Data transferred:         0.16 MB
    Response time:            0.03 secs
    Transaction rate:       307.69 trans/sec
    Throughput:           0.24 MB/sec
    Concurrency:            9.62
    Successful transactions:         100
    Failed transactions:             0
    Longest transaction:          0.25
    Shortest transaction:         0.00

    Stopping rails application...
    Rails application stopped
    Rails application test complete


    Starting standalone publishing and consuming benchmark...
    Publishing 5000 events...
           user     system      total        real
       1.460000   0.230000   1.690000 (  1.692004)
    Consuming 5000 events...
           user     system      total        real
       2.270000   0.570000   2.840000 (  3.339304)
    Benchmark complete

### Command Line Tools

#### Event Publish

    bundle exec bin/rabbit_feed produce --payload 'Event payload' --name 'Event name' --environment test --config spec/fixtures/configuration.yml --logfile test.log --require rabbit_feed.rb --verbose

Publishes an event. Note: until you've specified the event definitions, this will not publish any events. Options are as follows:

    --payload The payload of the event
    --name The name of the event
    --environment The environment to run in
    --config The location of the rabbit_feed configuration file
    --logfile The location of the log file
    --require The project file containing the dependancies
    --verbose Turns on DEBUG logging
    --help Print the available options

#### Consumer

    bundle exec bin/rabbit_feed consume --environment test --config spec/fixtures/configuration.yml --logfile test.log --require rabbit_feed.rb --pidfile rabbit_feed.pid --verbose --daemon

Starts a consumer. Note: until you've specified the event routing, this will not receive any events. Options are as follows:

    --environment The environment to run in
    --config The location of the rabbit_feed configuration file
    --logfile The location of the log file
    --require The project file containing the dependancies (only necessary if running with non-rails application)
    --pidfile The location at which to write a pid file
    --verbose Turns on DEBUG logging
    --daemon Run the consumer as a daemon
    --help Print the available options

## Installation

Add this line to your application's Gemfile:

    gem 'rabbit_feed', git: 'git@github.com:simplybusiness/rabbit_feed.git'

### Configuration

Create a `config/rabbit_feed.yml` file. The following options can be specified:

    environment:
      host: RabbitMQ host
      user: RabbitMQ user name
      password: RabbitMQ password
      application: Application name

Sample:

    development:
      host: localhost
      user: guest
      password: guest
      application: beavers

Note that this gem uses Airbrake for exception notifications, so your project will need to have Airbrake configured.

### Initialisation

If installing in a rails application, the following should be defined in `config/initializers/rabbit_feed.rb`:

```ruby
RabbitFeed.instance_eval do
  self.log                     = Logger.new (Rails.root.join 'log', 'rabbit_feed.log')
  self.log.level               = Logger::INFO
  self.environment             = Rails.env
  self.configuration_file_path = Rails.root.join 'config', 'rabbit_feed.yml'
end
# Define the events (if producing)
EventDefinitions do
  define_event('user_creates_beaver', version: '1.0.0') do
    defined_as do
      'A beaver has been created'
    end
    payload_contains do
      field('beaver_name', type: 'string', definition: 'The name of the beaver')
    end
  end
end
# Define the event routing (if consuming)
EventRouting do
  accept_from('beavers') do
    event('foo') do |event|
      # Do something...
    end
  end
end
```

### Producing events

The producer defines the events and their payloads using the Event Definitions DSL (see below for example). In a rails app, this can be defined in the initialiser.

To produce an event:

```ruby
require 'rabbit_feed_producer'
RabbitFeed::Producer.publish_event 'Event name', { 'payload_field' => 'payload field value' }
```

**Event name:** This tells you what the event is.

**Event payload:** This is the data about the event. This should be a hash.

The event will be published to the `amq.topic` exchange on RabbitMQ with a routing key having the pattern of:  `[environment].[producer application name].[event name]`.

If running with Unicorn, you must reconnect to RabbitMQ after the workers are forked due to how Unicorn forks its child processes. Add the following to your `config/unicorn.rb`:

```ruby
after_fork do |server, worker|
  require 'rabbit_feed'
  RabbitFeed::Producer.reconnect!
end
```

To prevent RabbitFeed from firing events during tests, add the following to `spec_helper.rb`:

```ruby
config.before :each do
  RabbitFeed::Producer.stub!
end
```

#### RSpec Matcher

To verify that your application publishes an event, use the custom RSpec matcher provided with this application.

Add the following RSpec configuration to `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  config.include(RabbitFeed::RSpecMatchers)
end
```

The expectation looks like this:

```ruby
require 'spec_helper'

describe BeaversController do

  describe 'POST create' do
    it 'publishes a create event' do
      expect{
        post :create, beaver: { name: 'beaver' }
      }.to publish_event('user_creates_beaver', { 'beaver_name' => 'beaver' })
    end
  end
end
```

### Consuming events

The consumer defines to which events it will subscribe as well as how it handles events using the Event Routing DSL (see below for example). In a rails app, this can be defined in the initialiser.

An `Event` contains the following information:

    `environment` The environment in which the event was created (e.g. development, test, production)
    `application` The name of the application that generated the event (as specified in rabbit_feed.yml)
    `version` The version of the event
    `name` The name of the event
    `host` The hostname of the server on which the event was generated
    `created_at_utc` The time (in UTC) that the event was created
    `payload` The payload of the event

#### Running the consumer

    bundle exec rabbit_feed consume --environment development

See the `Consumer` section for a description of the arguments

## Event Definitions DSL

Provides a means to define all events that are published by an application. Defines the event names and the payload associated with each event. The DSL is converted into a schema that is serialized along with the event payload, meaning the events are self-describing. This is accomplished using Apache [Avro](http://avro.apache.org/docs/current/). This also validates the event payload against its schema before it is published.

Here is an example DSL:

```ruby
EventDefinitions do
  define_event('user_creates_beaver', version: '1.0.0') do
    defined_as do
      'A beaver has been created'
    end
    payload_contains do
      field('beaver_name', type: 'string', definition: 'The name of the beaver')
    end
  end

  define_event('user_updates_beaver', version: '1.0.0') do
    defined_as do
      'A beaver has been updated'
    end
    payload_contains do
      field('beaver_name', type: 'string', definition: 'The name of the beaver')
    end
  end
end
```

This defines two events:

1. `user_creates_beaver`
2. `user_updates_beaver`

Each event has a mandatory string field in its payload, called `beaver_name`.

The available field types are described [here](http://avro.apache.org/docs/current/spec.html#schema_primitive).

Publishing a `user_creates_beaver` event would look like this:

```ruby
RabbitFeed::Producer.publish_event 'user_creates_beaver', { 'beaver_name' => @beaver.name }
```

## Event Routing DSL

Provides a means for consumers to specify to which events it will subscribe as well as how it handles events. This is accomplished using a custom DSL backed by a RabbitMQ [topic](http://www.rabbitmq.com/tutorials/tutorial-five-ruby.html) exchange.

Here is an example DSL:

```ruby
EventRouting do
  accept_from('beavers') do
    event('user_created_beaver') do |event|
      puts event.payload
    end
    event('user_updated_beaver') do |event|
      puts event.payload
    end
  end
end
```

This will subscribe to specified events originating from the `beavers` application. We have specified that we would like to subcribe to `user_created_beaver` and `user_updated_beaver` events. If either event type is received, we have specified that its payload will be printed to the screen.

When the consumer is started, it will create its queue named using this pattern: `[environment].[consumer application name]`. It will bind the queue to the `amq.topic` exchange on the routing keys as defined in the event routing. In this example, it will bind on:

    environment.beavers.user_created_beaver
    environment.beavers.user_updated_beaver

_Note: The consumer queues will automatically expire (delete) after 7 days without any consumer connections. This is to prevent unused queues from hanging around once their associated consumer has been terminated._

## TODO

* Allow for multiple users to share rabbitmq infrastructure in integration environment
* Event grammar, see: http://snowplowanalytics.com/blog/2013/08/12/towards-universal-event-analytics-building-an-event-grammar/. For additional info on event contexts, see: http://snowplowanalytics.com/blog/2014/01/27/snowplow-custom-contexts-guide/
* RSpec matcher to allow consumers to verify event routing
* Capistrano hooks
* Add routing key wilcard capabilities to DSL
* SBConf service definition?
* More elegant control of consumer (i.e. reload, quit, kill methods)
* Multi-threaded consumer

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
