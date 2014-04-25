require 'optparse'
require 'pidfile'

module RabbitFeed
  class Client

    DEFAULTS = {
      payload:      'test',
      require_path: '.',
      config_file:  'config/rabbit_feed.yml',
      logfile:      'log/rabbit_feed.log',
      pidfile:      'tmp/pids/rabbit_feed.pid',
      handler:      'RabbitFeed::EventHandler',
    }
    DEFAULTS.freeze

    attr_reader :command, :options

    def initialize arguments=ARGV
      @command = ARGV[0]
      @options = parse_options arguments

      set_logging
      set_configuration
      load_dependancies
    end

    def run
      send(command)
    end

    private

    def method_missing(name, *args, &block)
      puts "The action '#{name}' does not exist. Valid actions are: consume, produce"
      exit 1
    end

    def consume
      daemonize if options[:daemon]
      while true do
        begin
          RabbitFeed::Consumer.start
        rescue ConfigurationError => e
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
      RabbitFeed.log.level = options[:verbose] ? Logger::DEBUG : Logger::INFO
    end

    def set_configuration
      RabbitFeed.environment             = options[:environment]
      RabbitFeed.configuration_file_path = options[:config_file]
      RabbitFeed.event_handler_klass     = options[:handler]
      ENV['RACK_ENV'] = ENV['RAILS_ENV'] = RabbitFeed.environment
    end

    def load_dependancies
      if File.directory?(options[:require_path])
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

    def parse_options argv
      opts = {}

      parser = OptionParser.new do |o|

        o.on '-H', '--handler VAL', "Event handling class name" do |arg|
          opts[:handler] = arg
        end

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
