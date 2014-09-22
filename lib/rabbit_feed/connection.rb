module RabbitFeed
  module Connection
    extend ActiveSupport::Concern

    module ClassMethods

      def open &block
        unset_connection if closed?
        channel_pool.with do |channel|
          yield channel
        end
      end

      def closed?
        @connection.present? && @connection.closed?
      end

      def close
        RabbitFeed.log.debug "Closing connection: #{self.to_s}..."
        @connection.close unless closed?
        unset_connection
      rescue => e
        RabbitFeed.log.warn "Exception encountered whilst closing #{self.to_s}: #{e.message} #{e.backtrace}"
      end

      def unset_connection
        RabbitFeed.log.debug "Unsetting connection: #{self.to_s}..."
        @channel_pool = nil
        @connection   = nil
      end

      private

      def channel_pool
        @channel_pool ||= ConnectionPool.new(
          size:    RabbitFeed.configuration.pool_size,
          timeout: RabbitFeed.configuration.pool_timeout
        ) do
          new connection.create_channel
        end
      end

      def connection
        if @connection.nil?
          RabbitFeed.log.debug "Opening connection: #{self.to_s}..."
          @connection = Bunny.new({
            heartbeat:                 RabbitFeed.configuration.heartbeat,
            connect_timeout:           RabbitFeed.configuration.connect_timeout,
            host:                      RabbitFeed.configuration.host,
            user:                      RabbitFeed.configuration.user,
            password:                  RabbitFeed.configuration.password,
            port:                      RabbitFeed.configuration.port,
            network_recovery_interval: RabbitFeed.configuration.network_recovery_interval,
            logger:                    RabbitFeed.log,
          })
          @connection.start
        end

        @connection
      end
    end
  end
end
