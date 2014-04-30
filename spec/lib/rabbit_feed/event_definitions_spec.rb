require 'spec_helper'

module RabbitFeed
  describe EventRouting do
    before do
      EventDefinitions do
        dimension('customer', version: '1.0.0') do
          defined_as do
            'The definition of a customer'
          end
          field('id', type: 'string', definition: 'The definition of the id')
        end
        dimension('policy', version: '1.0.0') do
          defined_as do
            'The definition of a policy'
          end
          field('id', type: 'string', definition: 'The definition of the id')
        end
        event('customer_purchases_policy', version: '1.0.0') do
          defined_as do
            'The definition of a purchase'
          end
          payload_contains('customer', 'policy')
        end
      end
    end

    it 'should do something' do
      # p RabbitFeed::Producer.event_definitions['customer_purchases_policy'].schema
      RabbitFeed::Producer.event_definitions['customer_purchases_policy'].should_not be_nil
    end
  end
end
