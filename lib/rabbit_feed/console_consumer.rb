module RabbitFeed
  module ConsoleConsumer
    extend self

    APPLICATION_NAME = 'rabbit_feed_console'

    def init
      @event_count = 0
      set_application
      route_all_events
      puts welcome_message
      ask_to_purge_queue unless ConsumerConnection.instance.queue_depth.zero?
      puts "Ready. Press CTRL+C to exit."
    end

    def formatted event
      Formatter.new(event).to_s
    end

    def event_count_message
      "#{@event_count} events received."
    end

    def increment_event_count
      @event_count += 1
    end

    private

    def welcome_message
"""RabbitFeed console starting at #{Time.now.utc}...
Environment: #{RabbitFeed.environment}
Queue: #{RabbitFeed.configuration.queue}
"""
    end

    def ask_to_purge_queue
      puts "There are currently #{ConsumerConnection.instance.queue_depth} message(s) in the console's queue.\n"+
      "Would you like to purge the queue before proceeding? (y/N)>"
      response = STDIN.gets.chomp
      purge_queue if response == 'y'
    end

    def purge_queue
      ConsumerConnection.instance.purge_queue
      puts "Queue purged."
    end

    def route_all_events
      scope = self
      EventRouting do
        accept_from(:any) do
          event(:any) do |event|
            scope.increment_event_count
            puts (scope.formatted event)
            puts scope.event_count_message
          end
        end
      end
    end

    def set_application
      RabbitFeed.application = APPLICATION_NAME
    end

    class Formatter

      BORDER_WIDTH = 100
      BORDER_CHAR  = "-"
      DIVIDER_CHAR = "*"
      NEWLINE      = "\n"

      attr_reader :event

      def initialize event
        @event = event
      end

      def to_s
        [header, metadata, divider, payload, footer].join(NEWLINE)
      end

      private

      def header
        event_detail = "#{event.name}: #{event.created_at_utc}"
        border_filler = BORDER_CHAR*((BORDER_WIDTH - event_detail.length)/2)
        border_filler+event_detail+border_filler
      end

      def footer
        BORDER_CHAR*BORDER_WIDTH
      end

      def metadata
        pretty_print_hash 'Event metadata', event.metadata
      end

      def divider
        DIVIDER_CHAR*BORDER_WIDTH
      end

      def payload
        pretty_print_hash 'Event payload', event.payload
      end

      def pretty_print_hash description, hash
        '#' + description + NEWLINE +
        hash.keys.sort.map do |key|
          "#{key}: #{hash[key]}"
        end.join(NEWLINE)
      end
    end
  end
end
