# RabbitFeed

![RabbitFeed logo](https://cloud.githubusercontent.com/assets/768254/3286432/b4e65e7e-f548-11e3-9c91-f7d04f489cf3.png)

A gem providing asynchronous event publish and subscribe capabilities with RabbitMQ.

## Core concepts

* Fire and forget: Application can publish an event and it has no knowledge/care of how that event is consumed.
* Persistent events: Once an event has been published, it will persist until it has been processed successfully.
* Self-describing events: The event not only contains a payload, but also a schema that describes that payload.
* Multiple subscribers: Multiple applications can subscribe to the same events.
* Event versioning: Consumers can customize event handling based on the event version.

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

### Initialisation

If installing in a rails application, the following should be defined in `config/initializers/rabbit_feed.rb`:

```ruby
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

You may also override the log location (defaults to `STDOUT`), the environment (defaults to the `RAILS_ENV`), and the path to the RabbitFeed config file (defaults to `config/rabbit_feed.yml`) in the initializer, like this:

```ruby
RabbitFeed.instance_eval do
  self.log                     = Logger.new (Rails.root.join 'log', 'rabbit_feed.log')
  self.environment             = Rails.env
  self.configuration_file_path = Rails.root.join 'config', 'rabbit_feed.yml'
end
```

## Producing events

The producer defines the events and their payloads using the [Event Definitions DSL](https://github.com/simplybusiness/rabbit_feed#event-definitions-dsl). In a rails app, this can be defined in the [initialiser](https://github.com/simplybusiness/rabbit_feed#initialisation).

To produce an event:

```ruby
require 'rabbit_feed'
RabbitFeed::Producer.publish_event 'Event name', { 'payload_field' => 'payload field value' }
```

**Event name:** This tells you what the event is.

**Event payload:** This is the data about the event. This should be a hash.

The event will be published to the configured exchange on RabbitMQ (`amq.topic` by default) with a routing key having the pattern of:  `[environment].[producer application name].[event name]`.

### Returned Events

In the case that there are no consumers configured to subscribe to an event, the event will be returned to the producer. The returned event will be logged, and if your project uses [Airbrake](https://airbrake.io), an error will be reported there.

### Testing the Producer

To prevent RabbitFeed from publishing events to RabbitMQ during tests, add the following to `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  RabbitFeed::TestingSupport.capture_published_events(config)
end
```

#### RSpec

To verify that your application publishes an event, use the custom RSpec matcher provided with this application.

To make the custom RSpec matcher available to your tests, add the following to `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  RabbitFeed::TestingSupport.setup(config)
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

## Consuming events

The consumer defines to which events it will subscribe as well as how it handles events using the [Event Routing DSL](https://github.com/simplybusiness/rabbit_feed#event-routing-dsl). In a rails app, this can be defined in the [initialiser](https://github.com/simplybusiness/rabbit_feed#initialisation).

An `Event` contains the following information:

- `metadata` Information about the event, including:
  - `environment` The environment in which the event was created (e.g. development, test, production)
  - `application` The name of the application that generated the event (as specified in rabbit_feed.yml)
  - `version` The version of the event payload (as specified in the event definition)
  - `name` The name of the event
  - `host` The hostname of the server on which the event was generated
  - `created_at_utc` The time (in UTC) that the event was created
  - `gem_version` The version of RabbitFeed by which the event was created
- `payload` The payload of the event

### Running the consumer

    bundle exec rabbit_feed consume --environment development

More information about the consumer command line options can be found [here](https://github.com/simplybusiness/rabbit_feed#consumer).

### Event Processing Errors

In the case that your consumer raises an error whilst processing an event, the error will be logged. If your project uses [Airbrake](https://airbrake.io), the error will also be reported there. The event that was being processed will remain on the RabbitMQ queue, and will be redelivered to the consumer until it is processed without error.

### Testing the Consumer

If you want to test that your routes are behaving as expected without actually using RabbitMQ, you can invoke `rabbit_feed_consumer.consume_event(event)`. The following is an example:

```ruby
describe 'consuming events' do
  accumulator = []

  let(:define_route) do
    EventRouting do
      accept_from('application_name') do
        event('event_name') do |event|
          accumulator << event
        end
      end
    end
  end

  let(:event) { RabbitFeed::Event.new({'application' => 'application_name', 'name' => 'event_name'}, {'stuff' => 'some_stuff'}) }

  before { define_route }

  it 'route to the correct service' do
    rabbit_feed_consumer.consume_event(event)
    expect(accumulator.size).to eq(1)
  end
end
```

To make the `rabbit_feed_consumer` method available to your tests, add the following to `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  RabbitFeed::TestingSupport.setup(config)
end
```

## Command Line Tools

### Event Publish

    bundle exec bin/rabbit_feed produce --payload 'Event payload' --name 'Event name' --environment test --config spec/fixtures/configuration.yml --logfile test.log --require rabbit_feed.rb --verbose

Publishes an event. Note: until you've specified the [event definitions](https://github.com/simplybusiness/rabbit_feed#event-definitions-dsl), this will not publish any events. Options are as follows:

    --payload The payload of the event
    --name The name of the event
    --environment The environment to run in
    --config The location of the rabbit_feed configuration file
    --logfile The location of the log file
    --require The project file containing the dependancies
    --verbose Turns on DEBUG logging
    --help Print the available options

### Consumer

    bundle exec bin/rabbit_feed consume --environment test --config spec/fixtures/configuration.yml --logfile test.log --require rabbit_feed.rb --pidfile rabbit_feed.pid --verbose --daemon

Starts a consumer. Note: until you've specified the [event routing](https://github.com/simplybusiness/rabbit_feed#event-routing-dsl), this will not receive any events. Options are as follows:

    --environment The environment to run in
    --config The location of the rabbit_feed configuration file
    --logfile The location of the log file
    --require The project file containing the dependancies (only necessary if running with non-rails application)
    --pidfile The location at which to write a pid file
    --verbose Turns on DEBUG logging
    --daemon Run the consumer as a daemon
    --help Print the available options

### Stopping the consumer

    bundle exec bin/rabbit_feed shutdown

_This only applies if you've started the consumer with the `--daemon` option._

## Event Definitions DSL

Provides a means to define all events that are published by an application. Defines the event names and the payload associated with each event. The DSL is converted into a schema that is serialized along with the event payload, meaning the events are self-describing. This is accomplished using Apache [Avro](http://avro.apache.org/docs/current/). This also validates the event payload against its schema before it is published.

Event definitions are cumulative, meaning you can load multiple `EventDefinitions` blocks.

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

Event routing definitions are cumulative, meaning you can load multiple `EventRouting` blocks.

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

## Delivery Semantics

RabbitFeed provides 'at least once' delivery semantics. There are two use-cases where an event may be delivered more than once:

1. If the subscriber raises an exception whilst processing an event, RabbitFeed will re-deliver the event to the subscriber until the event is processed without error.
1. If an event is pushed to the subscriber, and the subscriber loses connectivity with RabbitMQ before it can send an acknowledgement back to RabbitMQ, RabbitMQ will push the event again once connectivity has been restored.

It is advisable to run RabbitFeed in a [clustered](https://www.rabbitmq.com/clustering.html) RabbitMQ environment to prevent the loss of messages in the case that a RabbitMQ node is lost. By default, RabbitFeed will declare queues to be mirrored across all nodes of the cluster.

## Developing

_See [./DEVELOPING.md](./DEVELOPING.md) for instructions on how to develop RabbitFeed_
