# RabbitFeed

A gem providing asynchronous event publish and subscribe capabilities with RabbitMQ.

## Core concepts

* Fire and forget: Application can publish an event and it has no knowledge/care of how that event is consumed.
* Persistent events: Once an event has been published, it will persist until it has been processed successfully.
* Event order preserved: Events are received in the order they were generated.
* Multiple subscribers: Multiple applications can subscribe to the same events.
* Application versioning: Allows for multiple [incompatible] versions of application events to exist simulaneously.

## Developing

### Requirements

1. RabbitMQ running locally

        brew install rabbitmq
        rabbitmq-server

The management interface can be found [here](http://localhost:15672/). The default login is `guest/guest`. You can view exchanges [here](http://localhost:15672/#/exchanges) and queues [here](http://localhost:15672/#/queues).

### Running Tests

This will run the specs and the features:

    bundle exec rake

### Running the example project

After doing any dev work, it is good practice to verify you haven't broken the examples. Run the examples like this:

    ./run_example

You should see the following output:

    Starting non rails application consumer...
    Non rails application consumer started
    Starting rails application consumer...
    Rails application consumer started
    Starting rails application...
    Rails application started
    Triggering event...
    NonRailsApp::EventHandler - Consumed event: beaver.created with payload: {"id":10,"name":"04/24/14 13:40:43","created_at":"2014-04-24T12:40:44.618Z","updated_at":"2014-04-24T12:40:44.618Z"}
    Event triggered
    RailsApp::EventHandler - Consumed event: event.processed with payload: {:event_name=>"beaver.created", :original_payload=>"{\"id\":10,\"name\":\"04/24/14 13:40:43\",\"created_at\":\"2014-04-24T12:40:44.618Z\",\"updated_at\":\"2014-04-24T12:40:44.618Z\"}"}
    Stopping non rails application consumer...
    Non rails application consumer stopped
    Stopping rails application consumer...
    Rails application consumer stopped
    Stopping rails application...
    Rails application stopped

### Command Line Tools

#### Event Publish

    bundle exec bin/rabbit_feed produce --payload 'Event payload' --name 'Event name' --environment test --config spec/fixtures/configuration.yml --logfile test.log --require rabbit_feed.rb --verbose

Publishes an event. Options are as follows:

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
      version: Application version number

Sample:

    development:
      host: localhost
      user: guest
      password: guest
      application: beavers
      version: 1.0.0

Note that this gem uses Airbrake for exception notifications, so your project will need to have Airbrake configured.

### Initialisation

If installing in a rails application, the following should be defined in `config/initializers/rabbit_feed.rb`:

```ruby
# Require the producer (if producing)
require 'rabbit_feed_producer'
# Require the consumer (if consuming)
require 'rabbit_feed_consumer'
# Set the logger
RabbitFeed.log                     = Logger.new(Rails.root.join('log/rabbit_feed.log'))
# Set the environment
RabbitFeed.environment             = Rails.env
# Set the config file location
RabbitFeed.configuration_file_path = File.join(Rails.root, 'config/rabbit_feed.yml')
# Set the class that will handle incoming events (if consuming)
RabbitFeed.event_handler           = RabbitFeed::EventHandler
# Define the event routing (if consuming)
EventRouting do
  accept_from(application: 'beaver', version: '1.0.0') do
    event('foo')
  end
end
```

### Producing events

```ruby
require 'rabbit_feed_producer'
RabbitFeed::Producer.publish_event 'Event name', 'Event payload'
```

**Event name:** This tells you what the event is.

**Event payload:** This is the data about the event. This could be anything: text, ruby class, JSON, etc.

The event will be published to the `amq.topic` exchange on RabbitMQ with a routing key having the pattern of:  `[environment].[producer application name].[producer application version].[event name]`.

If running with Unicorn, you must reconnect to RabbitMQ after the workers are forked due to how Unicorn forks its child processes. Add the following to your `config/unicorn.rb`:

```ruby
after_fork do |server, worker|
  require 'rabbit_feed_producer'
  RabbitFeed.reconnect!
end
```

To prevent RabbitFeed from firing events during tests, add the following to `spec_helper.rb`:

```ruby
config.before :each do
  RabbitFeed.stub!
end
```

### Consuming events

Create an `EventHandler` class, which will be called when you consume an event. Example:

```ruby
class EventHandler < RabbitFeed::EventHandler

  def handle_event event
    # Do something
  end
end
```

An `Event` contains the following information:

    `environment` The environment in which the event was created (e.g. development, test, production)
    `application` The name of the application that generated the event (as specified in rabbit_feed.yml)
    `version` The version of the application that generated the event (as specified in rabbit_feed.yml)
    `name` The name of the event
    `host` The hostname of the server on which the event was generated
    `created_at_utc` The time (in UTC) that the event was created
    `payload` The payload of the event

Define event routing using the Event Routing DSL (see below for example). In a rails app, this can be defined in the initialiser.

#### Running the consumer

    bundle exec rabbit_feed consume --environment development

See the `Consumer` section for a description of the arguments

## Event Routing DSL

We need a way for consumers to specify to which types of events they wish to subscribe. This is accomplished using a custom DSL backed by a RabbitMQ [topic](http://www.rabbitmq.com/tutorials/tutorial-five-ruby.html) exchange.

Here is an example DSL:

```ruby
EventRouting do
  accept_from(application: 'beavers', version: '1.0.0') do
    event('beaver.created')
    event('beaver.updated')
  end
end
```

This will subscribe to specified events originating from the `beavers` application at version `1.0.0`. We have specified that we would like to subcribe to `beaver.created` and `beaver.updated` events.

When the consumer is started, it will create its queue named using this pattern: `[environment].[consumer application name].[consumer application version]`. This allows for multiple versions of a consumer application to be running simultaneuosly. It will bind the queue to the `amq.topic` exchange on the routing keys as defined in the event routing. In this example, it will bind on:

    environment.beavers.1.0.0.beaver.created
    environment.beavers.1.0.0.beaver.updated

## TODO

* Ability to run multiple consumer instances on the same server (pid file conflict)
* Capistrano hooks
* Add routing key wilcard capabilities to DSL
* SBConf service definition
* More elegant control of consumer (i.e. reload, quit, kill methods)
* Multi-threaded consumer

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
