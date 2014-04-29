require 'spec_helper'
require 'ostruct'

module RabbitFeed
  describe Event do
    let(:application) { 'rabbit_feed' }
    let(:version)     { '1.0.0' }
    let(:name)        { 'name' }
    let(:payload)     { { pay: :load } }
    subject { described_class.new application, version, name, payload }

    describe '.new' do

      context 'with valid arguments' do

        its(:application)    { should eq 'rabbit_feed' }
        its(:version)        { should eq '1.0.0' }
        its(:name)           { should eq 'name' }
        its(:host)           { should_not be_blank }
        its(:environment)    { should eq 'test' }
        its(:created_at_utc) { should be_a Time }
        its(:payload)        { should eq({ pay: :load }) }
      end

      context 'with invalid arguments' do
        let(:application) {}
        let(:version)     {}
        let(:name)        {}
        let(:payload)     {}

        it 'should raise an error' do
          expect{ subject }.to raise_error Error
        end
      end
    end

    describe '#routing_key' do

      its(:routing_key) { should eq 'test.rabbit_feed.1.0.0.name' }
    end

    describe 'serialization' do
      let(:fields) { [:application, :version, :name, :environment, :created_at_utc, :payload] }

      it 'can be serialized and deserialized' do
        serialized   = subject.serialize
        deserialized = Event.deserialize serialized
        fields.each do |field|
          subject.send(field).should eq deserialized.send(field)
        end
      end

      context 'with nested classes in payload' do
        let(:payload) { {a: OpenStruct.new({ b: OpenStruct.new({ d: :e }) })} }

        it 'can be serialized and deserialized' do
          serialized   = subject.serialize
          deserialized = Event.deserialize serialized
          subject.payload.should eq deserialized.payload
        end
      end

      context 'with big decimal in payload' do
        let(:payload) { {a: (BigDecimal.new '1.1') } }

        it 'can be serialized and deserialized' do
          serialized   = subject.serialize
          deserialized = Event.deserialize serialized
          subject.payload.should eq deserialized.payload
        end
      end
    end
  end
end
