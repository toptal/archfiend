module Archfiend
  class ThreadLoop
    extend Forwardable
    include SharedLoop::Runnable

    EXCEPTION_DELAY = 1 # Seconds to sleep for after rescuing recoverable exception

    def_delegator :app, :logger

    attr_accessor :app

    class << self
      attr_reader :subclasses

      # Collects all subclasses in the class instance variable
      def inherited(child_class)
        @subclasses ||= []
        @subclasses.push(child_class)
      end

      def start_all(app)
        (subclasses || []).map do |thread_loop_class|
          th = Thread.new do
            instance = thread_loop_class.new
            instance.app = app
            app.logger.info "Starting thread #{thread_loop_class}"
            instance.run
          end
          th[:name] = thread_loop_class.name
          th
        end
      end
    end
  end
end
