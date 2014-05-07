require 'spec_helper'

module RabbitFeed
  describe Event do
    let(:schema)  { double(:schema) }
    let(:payload) { { 'customer_id' => '123' } }

    subject { described_class.new schema, payload }

    describe '.new' do

      it { should be_valid }
      its(:schema)  { should eq schema }
      its(:payload) { should eq({ 'customer_id' => '123' }) }

      context 'when schema is nil' do
        let(:schema) {}

        it 'should raise an error' do
          expect{ subject }.to raise_error Error
        end
      end

      context 'when payload is nil' do
        let(:payload) {}

        it 'should raise an error' do
          expect{ subject }.to raise_error Error
        end
      end
    end
  end
end
