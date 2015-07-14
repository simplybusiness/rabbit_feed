module RabbitFeed
  class JsonLogFormatter < Logger::Formatter
    def self.call(severity, time, progname, msg)
      {
        severity: severity,
        time: time.utc.iso8601(6),
        progname: progname,
        message: msg,
      }.to_json + "\n"
    end
  end
end
