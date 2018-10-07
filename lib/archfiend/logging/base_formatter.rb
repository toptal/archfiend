module Archfiend
  class Logging
    class BaseFormatter
      STACK_ENTRIES_TO_SKIP = 9 # How many stack frames to exclude from the backtrace
      SEVERITY_STACK_ENTRIES_COUNT = { # How many stack frames to include
        'FATAL' => 10,
        'ERROR' => 10,
        'WARN' => 5,
        'INFO' => 2,
        'DEBUG' => 2,
        'UNKNOWN' => 2
      }.freeze

      private

      def description_and_backtrace(severity, msg)
        description = nil
        backtrace = nil

        if msg.is_a?(Hash)
          description = msg[:message]
          backtrace = msg[:backtrace]&.slice(0, SEVERITY_STACK_ENTRIES_COUNT[severity])
        else
          description = msg
        end
        backtrace ||= caller.slice(STACK_ENTRIES_TO_SKIP - 1, SEVERITY_STACK_ENTRIES_COUNT[severity])
        [description, backtrace]
      end

      def tid
        Thread.current[:tid] ||= (Thread.current.object_id ^ ::Process.pid).to_s(36)
      end
    end
  end
end
