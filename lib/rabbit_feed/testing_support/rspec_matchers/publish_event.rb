module RabbitFeed
  module TestingSupport
    module RSpecMatchers
      class PublishEvent
        attr_reader :expected_event

        def initialize(expected_event, expected_payload)
          @expected_event   = expected_event
          @expected_payload = expected_payload
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

          actual_event = TestingSupport.published_events.detect do |event|
            event.name == expected_event
          end

          received_expected_event = actual_event.present?

          with_expected_payload = negative_expectation
          if received_expected_event && !with_expected_payload
            actual_payload        = actual_event.payload
            with_expected_payload = expected_payload.nil? || actual_payload == expected_payload
          end

          return received_expected_event && with_expected_payload
        end

        alias == matches?

        def does_not_match?(given_proc)
          !matches?(given_proc, :negative_expectation)
        end

        def failure_message
          "expected #{expected_event} with #{expected_payload || 'some payload'} but instead received #{received_events_message}"
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

        def with(expected_payload=nil, &block)
          if !!@expected_payload
            ::Kernel.warn "`publish_event` was called with an expected payload already, anything in `with` is ignored"
          else
            @expected_payload = expected_payload || block
          end

          self
        end

        private

        def expected_payload
          @expected_payload.respond_to?(:call) ? @expected_payload.call : @expected_payload
        end

        def received_events_message
          if TestingSupport.published_events.any?
            TestingSupport.published_events.map do |received_event|
              "#{received_event.name} with #{received_event.payload}"
            end
          else
            'no events'
          end
        end
      end

      def publish_event(expected_event, expected_payload = nil)
        PublishEvent.new(expected_event, expected_payload)
      end
    end
  end
end
