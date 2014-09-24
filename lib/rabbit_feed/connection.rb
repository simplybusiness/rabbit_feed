module RabbitFeed
  module Connection
    extend ActiveSupport::Concern

    module ClassMethods

      def default_connection_options
        {
          heartbeat:                 RabbitFeed.configuration.heartbeat,
          connect_timeout:           RabbitFeed.configuration.connect_timeout,
          host:                      RabbitFeed.configuration.host,
          user:                      RabbitFeed.configuration.user,
          password:                  RabbitFeed.configuration.password,
          port:                      RabbitFeed.configuration.port,
          network_recovery_interval: RabbitFeed.configuration.network_recovery_interval,
          logger:                    RabbitFeed.log,
        }
      end

      def connection
        if @connection.nil?
          retry_on_exception do
            RabbitFeed.log.debug "Opening connection: #{self.to_s}..."
            @connection = Bunny.new connection_options
            @connection.start
          end
        end

        @connection
      end

      def channel_pool
        @channel_pool ||= ConnectionPool.new(
          size:    RabbitFeed.configuration.pool_size,
          timeout: RabbitFeed.configuration.pool_timeout
        ) do
          new connection.create_channel
        end
      end

      def open &block
        channel_pool.with do |channel|
          yield channel
        end
      end

      def closed?
        @connection.present? && @connection.closed?
      end

      def unset_connection
        RabbitFeed.log.debug "Unsetting connection: #{self.to_s}..."
        @channel_pool = nil
        @connection   = nil
      end

      def close
        RabbitFeed.log.debug "Closing connection: #{self.to_s}..."
        @connection.close if @connection.present? && !closed?
        unset_connection
      rescue => e
        RabbitFeed.log.warn "Exception encountered whilst closing #{self.to_s}: #{e.message} #{e.backtrace}"
      end

      def retry_on_exception tries=3, &block
        yield
      rescue Bunny::ConnectionClosedError
        raise # There is no point in retrying if the connection is closed
      rescue => e
        RabbitFeed.log.warn "Exception encountered; #{tries - 1} tries remaining. #{self.to_s}: #{e.message} #{e.backtrace}"
        unless (tries -= 1).zero?
          retry
        end
        raise
      end

      def retry_on_closed_connection tries=3, &block
        yield
      rescue Bunny::ConnectionClosedError => e
        RabbitFeed.log.warn "Closed connection exception encountered; #{tries - 1} tries remaining. #{self.to_s}: #{e.message} #{e.backtrace}"
        unless (tries -= 1).zero?
          unset_connection
          sleep RabbitFeed.configuration.network_recovery_interval
          retry
        end
        raise
      end
    end
  end
end
