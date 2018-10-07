module Archfiend
  module SharedLoop
    module Runnable
      def run
        loop do
          begin
            wrap_iterate
          rescue => e
            log_exception(e)
            sleep self.class.const_get('EXCEPTION_DELAY')
          end
        end
      end

      def log_exception(exception)
        logger.error(message: exception.to_s, backtrace: exception.backtrace)
      end

      private

      def wrap_iterate
        iterate
      end
    end
  end
end
