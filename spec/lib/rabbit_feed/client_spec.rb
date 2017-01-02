module RabbitFeed
  describe Client do
    let(:command)     { 'consume' }
    let(:logfile)     { 'test.log' }
    let(:pidfile)     { './test.pid' }
    let(:config_file) { 'spec/fixtures/configuration.yml' }
    let(:environment) { 'test' }
    let(:require_file) { 'rabbit_feed.rb' }
    let(:application) { 'rabbit_feed_test' }
    let(:arguments) do
      [
        command,
        '--environment',
        environment,
        '--config',
        config_file,
        '--logfile',
        logfile,
        '--pidfile',
        pidfile,
        '--require',
        require_file,
        '--application',
        application,
        '--daemon'
      ]
    end
    before do
      RabbitFeed.environment = nil
      RabbitFeed.application = nil
      RabbitFeed.log = nil
      RabbitFeed.configuration_file_path = nil
    end
    subject { described_class.new arguments }

    describe '.new' do
      it { should be_valid }

      it 'sets the environment' do
        subject
        expect(RabbitFeed.environment).to eq 'test'
      end

      it 'sets the application' do
        subject
        expect(RabbitFeed.application).to eq 'rabbit_feed_test'
      end

      it 'sets the logger' do
        subject
        expect(RabbitFeed.log).to be_a Logger
      end

      it 'sets the configuration' do
        subject
        expect(RabbitFeed.configuration).to be_a Configuration
      end

      context 'when the command is invalid' do
        let(:command) { 'blah' }

        it 'should be invalid' do
          expect { subject }.to raise_error Error
        end
      end

      context 'when the log file path is not present' do
        let(:logfile) { '/blah/blah.log' }

        it 'should be invalid' do
          expect { subject }.to raise_error Error
        end
      end

      context 'when the pid file path is not present' do
        let(:pidfile) { '/blah/blah.pid' }

        it 'should be invalid' do
          expect { subject }.to raise_error Error
        end
      end

      context 'when the config file is not present' do
        let(:config_file) { '/blah/blah.yml' }

        it 'should be invalid' do
          expect { subject }.to raise_error Error
        end
      end

      context 'when the environment is not present' do
        let(:environment) { '' }
        before do
          ENV['RAILS_ENV'] = nil
          ENV['RACK_ENV']  = nil
        end

        it 'should be invalid' do
          expect { subject }.to raise_error Error
        end

        context 'when the RAILS_ENV is present' do
          before { ENV['RAILS_ENV'] = 'test' }
          after do
            ENV['RAILS_ENV'] = nil
            ENV['RACK_ENV']  = nil
          end

          it { should be_valid }
        end
      end

      context 'when requiring a directory in a non rails app' do
        let(:require_file) { './' }

        it 'should be invalid' do
          expect { subject }.to raise_error Error
        end
      end
    end
  end
end
