module RabbitFeed
  module ConnectionConcern
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

      def with_connection &block
        connection_pool.with do |connection|
          yield connection
        end
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
          sleep 1
          retry
        end
        raise
      end

      def close
        RabbitFeed.log.debug "Closing connection: #{self.to_s}..."
        @bunny_connection.close if @bunny_connection.present? && !closed?
        unset_connection
      rescue => e
        RabbitFeed.log.warn "Exception encountered whilst closing #{self.to_s}: #{e.message} #{e.backtrace}"
      end

      def bunny_connection
        if @bunny_connection.nil?
          retry_on_exception do
            RabbitFeed.log.debug "Opening connection: #{self.to_s}..."
            @bunny_connection = Bunny.new connection_options
            @bunny_connection.start
          end
        end

        @bunny_connection
      end
      private :bunny_connection

      def connection_pool
        @connection_pool ||= ConnectionPool.new(
          size:    RabbitFeed.configuration.pool_size,
          timeout: RabbitFeed.configuration.pool_timeout
        ) do
          new bunny_connection.create_channel
        end
      end
      private :connection_pool

      def closed?
        @bunny_connection.present? && @bunny_connection.closed?
      end
      private :closed?

      def unset_connection
        RabbitFeed.log.debug "Unsetting connection: #{self.to_s}..."
        @connection_pool  = nil
        @bunny_connection = nil
      end
      private :unset_connection

    end
  end
end
