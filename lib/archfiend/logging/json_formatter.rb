module Archfiend
  class Logging
    # A JSON log formatter class, returns each entry as a JSON line
    class JSONFormatter < BaseFormatter
      def call(severity, datetime, progname, msg)
        description, backtrace = description_and_backtrace(severity, msg)
        log_hash = {
          '@timestamp': datetime.utc.iso8601(3),
          loglevel: severity&.downcase,
          pid: ::Process.pid,
          tid: tid,
          type: :archfiend,
          message: description,
          backtrace: backtrace,
          app: progname
        }
        Oj.dump(log_hash, mode: :compat) + "\n"
      end
    end
  end
end
