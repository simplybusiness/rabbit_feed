RSpec.shared_examples 'an operation that retries on exception' do |operation, exception_class|

  context 'less than three times' do

    it 'traps the exception' do
      tries = 0
      expect do
        subject.send(operation) do
          (tries += 1) < 3 ? (raise exception_class.new 'blah') : nil
        end
      end.to_not raise_error
    end
  end

  context 'three or more times' do

    it 'raises the exception' do
      tries = 0
      expect do
        subject.send(operation) do
          tries += 1
          raise exception_class.new 'blah'
        end
      end.to raise_error exception_class
      expect(tries).to eq 3
    end
  end
end

RSpec.shared_examples 'an operation that does not retry on exception' do |operation, exception_class|

  it 'does not retry when the error is received' do
      tries = 0
      expect do
        subject.send(operation) do
          (tries += 1) < 3 ? (raise exception_class.new 'blah') : nil
        end
      end.to raise_error
  end
end
