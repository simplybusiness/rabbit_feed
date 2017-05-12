module RabbitFeed
  class Configuration
    include ActiveModel::Validations

    attr_reader :host, :hosts, :port, :user, :password, :application, :environment, :exchange, :heartbeat,
                :connect_timeout, :network_recovery_interval, :auto_delete_queue, :auto_delete_exchange,
                :consumer_exit_after_fail
    validates_presence_of :application, :environment, :exchange

    def initialize(options)
      RabbitFeed.log.info { { event: :initialize_configuration, options: options.merge(password: :redacted) } }

      @host                      = options[:host]
      @hosts                     = options[:hosts]
      @port                      = options[:port]
      @user                      = options[:user]
      @password                  = options[:password]
      @exchange                  = options[:exchange] || 'amq.topic'
      @heartbeat                 = options[:heartbeat]
      @connect_timeout           = options[:connect_timeout]
      @network_recovery_interval = options[:network_recovery_interval]
      @auto_delete_queue         = !!(options[:auto_delete_queue] || false)
      @auto_delete_exchange      = !!(options[:auto_delete_exchange] || false)
      @application               = options[:application]
      @environment               = options[:environment]
      @route_prefix_extension    = options[:route_prefix_extension]
      @consumer_exit_after_fail  = options[:consumer_exit_after_fail] || false
      validate!
    end

    def self.load(file_path, environment, application)
      RabbitFeed.log.info { { event: :load_configuration_file, file_path: file_path, environment: environment, application: application } }

      raise ConfigurationError, "The RabbitFeed configuration file path specified does not exist: #{file_path}" unless File.exist? file_path

      options = read_configuration_file file_path, environment
      options[:environment] = environment
      options[:application] = application if !!application
      new options
    end

    def route_prefix_extension
      ".#{@route_prefix_extension}" unless @route_prefix_extension.blank?
    end

    def queue
      "#{environment}#{route_prefix_extension}.#{application}"
    end

    def connection_options
      {}.tap do |options|
        options[:heartbeat] = heartbeat if heartbeat
        options[:connect_timeout] = connect_timeout if connect_timeout
        options[:host] = host if host
        options[:hosts] = hosts if hosts
        options[:user] = user if user
        options[:password] = password if password
        options[:port] = port if port
        options[:network_recovery_interval] = network_recovery_interval if network_recovery_interval
        options[:logger] = RabbitFeed.log
        options[:recover_from_connection_close] = true
        options[:threaded] = true
      end
    end

    private

    def self.read_configuration_file(file_path, environment)
      raw_configuration = YAML.safe_load(ERB.new(File.read(file_path)).result)
      HashWithIndifferentAccess.new(raw_configuration[environment] || {})
    end
    private_class_method :read_configuration_file

    def validate!
      raise ConfigurationError, errors.messages if invalid?
    end
  end
end
