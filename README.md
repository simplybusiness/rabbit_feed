# RabbitFeed

A gem providing asynchronous event publish and subscribe capabilities with RabbitMQ.

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
    NonRailsApp::EventHandler - Consumed event: beaver.created with payload: {"id":10,"name":"04/24/14 13:40:43","created_at":"2014-04-24T12:40:44.618Z","updated_at":"2014-04-24T12:40:44.618Z"}
    RailsApp::EventHandler - Consumed event: event.processed with payload: {:event_name=>"beaver.created", :original_payload=>"{\"id\":10,\"name\":\"04/24/14 13:40:43\",\"created_at\":\"2014-04-24T12:40:44.618Z\",\"updated_at\":\"2014-04-24T12:40:44.618Z\"}"}
    Stopping non rails application consumer...
    Non rails application consumer stopped
    Stopping rails application consumer...
    Rails application consumer stopped
    Stopping rails application...
    Rails application stopped

## Installation

Add this line to your application's Gemfile:

    gem 'rabbit_feed', git: 'git@github.com:simplybusiness/rabbit_feed.git'

### Producing events

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
