module RabbitFeed
  class Configuration
    include ActiveModel::Validations

    attr_reader :host, :port, :user, :password, :application, :environment, :version, :exchange
    validates_presence_of :host, :port, :user, :password, :application, :environment, :version, :exchange

    def initialize options
      RabbitFeed.log.debug "RabbitFeed initialising with options: #{options}..."

      @host        = options[:host]     || 'localhost'
      @port        = options[:port]     || 5672
      @user        = options[:user]     || 'guest'
      @password    = options[:password] || 'guest'
      @application = options[:application]
      @environment = options[:environment]
      @version     = options[:version]
      @exchange    = options[:exchange] || 'amq.topic'
      validate!
    end

    def self.load file_path, environment
      RabbitFeed.log.debug "Reading configurations from #{file_path} in #{environment}..."

      options = read_configuration_file file_path, environment
      new options.merge(environment: environment)
    end

    # def queue_name
    #   "#{environment}.#{application}.#{version}"
    # end

    # def routing_key event
    #   "#{environment}.#{application}.#{version}.#{event}"
    # end

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
