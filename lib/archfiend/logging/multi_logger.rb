module Archfiend
  class Logging
    # A basic class that forwards all log calls to loggers it was initialized with.
    class MultiLogger < BasicObject
      attr_reader :loggers

      # @param loggers [Array<Logger>] A list of loggers to forward messages to
      def initialize(*loggers)
        @loggers = loggers.flatten
        @responding_loggers = {}
      end

      private

      # @return [Object] The return value is forwarded from the first logger that responds to the method_name
      def method_missing(method_name, *args)
        return super unless responding_loggers(method_name).any?

        responding_loggers(method_name).map { |l| l.public_send(method_name, *args) }.first
      end

      def respond_to_missing?(symbol, include_private = false)
        responding_loggers(method_name).any? || super
      end

      def responding_loggers(method_name)
        @responding_loggers[method_name.to_sym] ||= @loggers.select { |l| l.respond_to?(method_name) }
      end
    end
  end
end
