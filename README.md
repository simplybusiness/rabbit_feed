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
RabbitFeed.instance_eval do
  self.log                     = Logger.new (Rails.root.join 'log', 'rabbit_feed.log')
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

## Producing events

The producer defines the events and their payloads using the Event Definitions DSL (see below for example). In a rails app, this can be defined in the initialiser.

To produce an event:

```ruby
require 'rabbit_feed'
RabbitFeed::Producer.publish_event 'Event name', { 'payload_field' => 'payload field value' }
```

**Event name:** This tells you what the event is.

**Event payload:** This is the data about the event. This should be a hash.

The event will be published to the `amq.topic` exchange on RabbitMQ with a routing key having the pattern of:  `[environment].[producer application name].[event name]`.

To prevent RabbitFeed from firing events during tests, add the following to `spec_helper.rb`:

```ruby
config.before :each do
  RabbitFeed::Producer.stub!
end
```

### Aiding testing and the RSpec Matcher

To verify that your application publishes an event, use the custom RSpec matcher provided with this application.

Add the following RSpec configuration to `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  config.include(RabbitFeed::TestingSupport::RSpecMatchers)
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

If you want to test that your routes are behaving as expected without actually using *Rabbit* infrastructure, you can include the module `TestHelpers` in your tests and then invoke `rabbit_feed_consumer.consume_event(event)`. Following is an example:

```ruby
describe 'consuming events' do

  include RabbitFeed::TestingSupport::TestingHelpers

  accumulator = []

  let(:define_route) do
    EventRouting do
      accept_from('app') do
        event('ev') do |event|
          accumulator << event
        end
      end
    end
  end

  let(:event) { {'application' => 'app', 'name' => 'ev', 'stuff' => 'some_stuff'} }

  before { define_route }

  it 'route to the correct service' do
    rabbit_feed_consumer.consume_event(event)
    expect(accumulator.size).to eq(1)
  end
end
```

## Consuming events

The consumer defines to which events it will subscribe as well as how it handles events using the Event Routing DSL (see below for example). In a rails app, this can be defined in the initialiser.

An `Event` contains the following information:

    `environment` The environment in which the event was created (e.g. development, test, production)
    `application` The name of the application that generated the event (as specified in rabbit_feed.yml)
    `version` The version of the event
    `name` The name of the event
    `host` The hostname of the server on which the event was generated
    `created_at_utc` The time (in UTC) that the event was created
    `payload` The payload of the event

### Running the consumer

    bundle exec rabbit_feed consume --environment development

See the `Consumer` section for a description of the arguments

## Command Line Tools

### Event Publish

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

### Consumer

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

## Developing

_See [./DEVELOPING.md](./DEVELOPING.md) for instructions on how to develop RabbitFeed_
