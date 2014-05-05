module RabbitFeed
  module RSpecMatchers
    class PublishEvent
      attr_reader :block, :actual_event, :actual_payload, :expected_event, :expected_payload, :received_events, :received_expected_event, :with_expected_payload

      def initialize(expected_event, expected_payload, &block)
        @block            = block
        @actual_event     = nil
        @actual_payload   = nil
        @expected_event   = expected_event
        @expected_payload = expected_payload
        @received_events  = []
        stub_publish
      end

      def matches?(given_proc, negative_expectation = false)
        @received_expected_event = false
        @with_expected_payload   = false
        @eval_block = false
        @eval_block_passed = false
        unless given_proc.respond_to?(:call)
          ::Kernel.warn "`publish_event` was called with non-proc object #{given_proc.inspect}"
          return false
        end

        given_proc.call

        @actual_event = received_events.detect do |event|
          event.name = expected_event
        end

        @received_expected_event = actual_event.present?

        if received_expected_event
          @actual_payload        = (strip_defaults_from actual_event.payload)
          @with_expected_payload = actual_payload == expected_payload
        end

        return received_expected_event && with_expected_payload
      end
      alias == matches?

      def does_not_match?(given_proc)
        !matches?(given_proc, :negative_expectation)
      end

      def failure_message
        "expected #{expected_event} with #{expected_payload} but instead received #{received_events_message}"
      end

      def failure_message_when_negated
        "expected no #{expected_event}"
      end

      def description
        "publish_event #{expected_event}"
      end

      private

      def strip_defaults_from payload
        payload.reject do |key, value|
          ['application','host','environment','created_at_utc','version','name'].include? key
        end
      end

      def received_events_message
        if received_events.any?
          received_events.map do |received_event|
            "#{received_event.name} with #{strip_defaults_from received_event.payload}"
          end
        else
          'no events'
        end
      end

      def stub_publish
        ProducerConnection.stub(:publish) do |serialized_event, routing_key|
          @received_events << (Event.deserialize serialized_event)
        end
      end
    end

    def publish_event(expected_event, expected_payload)
      PublishEvent.new(expected_event, expected_payload)
    end
  end
end
