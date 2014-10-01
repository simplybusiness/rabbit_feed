module RabbitFeed
  class Configuration
    include ActiveModel::Validations

    attr_reader :host, :port, :user, :password, :application, :environment, :exchange, :pool_size, :pool_timeout, :heartbeat, :connect_timeout, :network_recovery_interval, :auto_delete_queue, :auto_delete_exchange
    validates_presence_of :host, :port, :user, :password, :application, :environment, :exchange, :pool_size, :pool_timeout, :heartbeat, :connect_timeout, :network_recovery_interval

    def initialize options
      RabbitFeed.log.debug "RabbitFeed initialising with options: #{options}..."

      @host                      = options[:host]                      || 'localhost'
      @port                      = options[:port]                      || 5672
      @user                      = options[:user]                      || 'guest'
      @password                  = options[:password]                  || 'guest'
      @exchange                  = options[:exchange]                  || 'amq.topic'
      @pool_size                 = options[:pool_size]                 || 1
      @pool_timeout              = options[:pool_timeout]              || 5
      @heartbeat                 = options[:heartbeat]                 || 5
      @connect_timeout           = options[:connect_timeout]           || 10
      @network_recovery_interval = options[:network_recovery_interval] || 1
      @auto_delete_queue         = !!(options[:auto_delete_queue] || false)
      @auto_delete_exchange      = !!(options[:auto_delete_exchange] || false)
      @application               = options[:application]
      @environment               = options[:environment]
      validate!
    end

    def self.load file_path, environment
      RabbitFeed.log.debug "Reading configurations from #{file_path} in #{environment}..."

      options = read_configuration_file file_path, environment
      new options.merge(environment: environment)
    end

    def queue
      "#{environment}.#{application}"
    end

    private

    def self.read_configuration_file file_path, environment
      raw_configuration = YAML.load(ERB.new(File.read(file_path)).result)
      HashWithIndifferentAccess.new (raw_configuration[environment] || {})
    end

    def validate!
      raise ConfigurationError.new errors.messages if invalid?
    end
  end
end
