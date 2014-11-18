module RabbitFeed
  module TestingSupport
    module RSpecMatchers
      class PublishEvent
        attr_reader :expected_event, :expected_payload, :received_events

        def initialize(expected_event, expected_payload)
          @expected_event   = expected_event
          @expected_payload = expected_payload
          @received_events  = []
          stub_publish
        end

        def matches?(given_proc, negative_expectation = false)
          unless given_proc.respond_to?(:call)
            ::Kernel.warn "`publish_event` was called with non-proc object #{given_proc.inspect}"
            return false
          end

          begin
            given_proc.call
          rescue
          end

          actual_event = received_events.detect do |event|
            event.name == expected_event
          end

          received_expected_event = actual_event.present?

          with_expected_payload = negative_expectation
          if received_expected_event && !with_expected_payload
            actual_payload        = (strip_defaults_from actual_event.payload)
            with_expected_payload = actual_payload == expected_payload
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

        def negative_failure_message
          "expected no #{expected_event} event, but received one anyways"
        end

        alias failure_message_when_negated negative_failure_message

        def description
          "publish_event #{expected_event}"
        end

        def supports_block_expectations?
          true
        end

        private

        def strip_defaults_from payload
          payload.reject do |key, value|
            ['application', 'host', 'environment', 'created_at_utc', 'version', 'name'].include? key
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
end
