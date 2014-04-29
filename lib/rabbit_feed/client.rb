require 'optparse'
require 'pidfile'

module RabbitFeed
  class Client
    include ActiveModel::Validations

    DEFAULTS = {
      payload:      'test',
      require_path: '.',
      config_file:  'config/rabbit_feed.yml',
      logfile:      'log/rabbit_feed.log',
      pidfile:      'tmp/pids/rabbit_feed.pid',
    }
    DEFAULTS.freeze

    attr_reader :command, :options
    validates_presence_of :command, :options
    validates :command, inclusion: { in: %w(consume produce), message: "%{value} is not a valid command" }
    validate :log_file_path_exists
    validate :config_file_exists
    validate :require_path_valid
    validate :pidfile_path_exists, if: :daemonize?
    validate :environment_specified

    def initialize arguments=ARGV
      @command = arguments[0]
      @options = parse_options arguments
      validate!

      set_logging
      set_configuration
      load_dependancies
    end

    def run
      send(command)
    end

    private

    def validate!
      raise Error.new errors.messages if invalid?
    end

    def log_file_path_exists
      errors.add(:options, "log file path not found: '#{options[:logfile]}', specify this using the --logfile option") unless File.exists?(File.dirname(options[:logfile]))
    end

    def config_file_exists
      errors.add(:options, "configuration file not found: '#{options[:config_file]}', specify this using the --config option") unless File.exists?(options[:config_file])
    end

    def require_path_valid
      if require_rails? && !File.exist?("#{options[:require_path]}/config/application.rb")
        errors.add(:options, 'point rabbit_feed to a Rails 3/4 application or a Ruby file to load your worker classes with --require')
      end
    end

    def pidfile_path_exists
      errors.add(:options, "pid file path not found: '#{options[:pidfile]}', specify this using the --pidfile option") unless File.exists?(File.dirname(options[:pidfile]))
    end

    def environment_specified
      errors.add(:options, '--environment not specified') unless options[:environment].present?
    end

    def consume
      daemonize if daemonize?
      while true do
        begin
          RabbitFeed::Consumer.start
        rescue ConfigurationError
          raise
        rescue => e
          warn "#{e.message} #{e.backtrace}"
          Airbrake.notify e
        end
      end
    end

    def produce
      RabbitFeed::Producer.publish_event options[:name], options[:payload]
    end

    def set_logging
      RabbitFeed.log       = Logger.new(options[:logfile])
      RabbitFeed.log.level = verbose? ? Logger::DEBUG : Logger::INFO
    end

    def set_configuration
      RabbitFeed.environment             = options[:environment]
      RabbitFeed.configuration_file_path = options[:config_file]
      ENV['RACK_ENV'] = ENV['RAILS_ENV'] = RabbitFeed.environment
    end

    def load_dependancies
      if require_rails?
        require 'rails'
        require File.expand_path("#{options[:require_path]}/config/environment.rb")
        ::Rails.application.eager_load!
      else
        require options[:require_path]
      end
    end

    def daemonize
      Process.daemon(true, true)
      pid_path = File.split options[:pidfile]
      PidFile.new(piddir: pid_path[0], pidfile: pid_path[1])
    end

    def daemonize?
      options[:daemon]
    end

    def verbose?
      options[:verbose]
    end

    def require_rails?
      File.directory?(options[:require_path])
    end

    def parse_options argv
      opts = {}

      parser = OptionParser.new do |o|

        o.on '-m', '--payload VAL', "Payload of event to produce" do |arg|
          opts[:payload] = arg
        end

        o.on '-n', '--name VAL', "Name of event to produce" do |arg|
          opts[:name] = arg
        end

        o.on '-d', '--daemon', "Daemonize process" do |arg|
          opts[:daemon] = arg
        end

        o.on '-e', '--environment ENV', "Application environment" do |arg|
          opts[:environment] = arg
        end

        o.on '-r', '--require [PATH|DIR]', "Location of Rails application with workers or file to require" do |arg|
          opts[:require_path] = arg
        end

        o.on "-v", "--verbose", "Print more verbose output" do |arg|
          opts[:verbose] = arg
        end

        o.on '-C', '--config PATH', "Path to YAML config file" do |arg|
          opts[:config_file] = arg
        end

        o.on '-L', '--logfile PATH', "Path to writable logfile" do |arg|
          opts[:logfile] = arg
        end

        o.on '-P', '--pidfile PATH', "Path to pidfile" do |arg|
          opts[:pidfile] = arg
        end

        o.on '-V', '--version', "Print version and exit" do |arg|
          puts "RabbitFeed #{RabbitFeed::VERSION}"
          exit 0
        end
      end

      parser.banner = "rabbit_feed action [options]"
      parser.on_tail "-h", "--help", "Show help" do
        puts parser
        exit 1
      end
      parser.parse! argv
      DEFAULTS.merge opts
    end

  end
end
