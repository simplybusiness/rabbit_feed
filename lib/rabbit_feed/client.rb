require 'optparse'
require 'pidfile'

module RabbitFeed
  class Client

    DEFAULTS = {
      concurrency:  1,
      payload:      'test',
      require_path: '.',
      config_file:  'config/rabbit_feed.yml',
      logfile:      'log/rabbit_feed.log',
      pidfile:      'tmp/pids/rabbit_feed',
      handler:      'RabbitFeed::EventHandler',
    }
    DEFAULTS.freeze

    attr_reader :command, :options

    def initialize arguments=ARGV
      @command = ARGV[0]
      @options = parse_options arguments

      RabbitFeed.log = Logger.new(options[:logfile])
      RabbitFeed.log.level = options[:verbose] ? Logger::DEBUG : Logger::INFO
      RabbitFeed.environment = options[:environment]
      RabbitFeed.configuration_file_path = options[:config_file]
      RabbitFeed.event_handler_klass = options[:handler]

      ENV['RACK_ENV'] = ENV['RAILS_ENV'] = RabbitFeed.environment

      if File.directory?(options[:require_path])
        require 'rails'
        require File.expand_path("#{options[:require_path]}/config/environment.rb")
        ::Rails.application.eager_load!
      else
        require options[:require_path]
      end

      Process.daemon(true, true) if options[:daemon]

      pid_path = File.split options[:pidfile]
      PidFile.new(piddir: pid_path[0], pidfile: pid_path[1])

    end

    def run
      send(command)
    end

    private

    def consume
      RabbitFeed::Consumer.start
    end

    def produce
      RabbitFeed::Producer.publish_event 'Manual publish', options[:payload]
    end

    def parse_options argv
      opts = {}

      parser = OptionParser.new do |o|

        o.on '-h', '--handler VAL', "Event handling class name" do |arg|
          opts[:handler] = arg
        end

        o.on '-m', '--payload VAL', "Payload of message to produce" do |arg|
          opts[:payload] = arg
        end

        o.on '-c', '--concurrency INT', "Processor threads to use" do |arg|
          opts[:concurrency] = Integer(arg)
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
