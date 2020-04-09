module Archfiend
  class Logging
    # Simple formatter that includes both PID and a unique thread id
    class DefaultFormatter < BaseFormatter
      def call(severity, datetime, progname, msg)
        description, _backtrace = description_and_backtrace(severity, msg)

        "#{datetime.utc.iso8601(3)} #{::Process.pid} TID-#{tid} #{severity} -- #{progname}: #{description}\n"
      end
    end
  end
end
