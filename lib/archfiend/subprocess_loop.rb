module Archfiend
  class SubprocessLoop
    extend ::Forwardable
    include SharedLoop::Runnable

    EXCEPTION_DELAY = 1 # Seconds to sleep for after rescuing recoverable exception

    def_delegator :app, :logger

    attr_accessor :app

    class << self
      attr_reader :subclasses, :subprocess_pids

      def inherited(child_class)
        @subclasses ||= []
        @subclasses.push(child_class)
        @subprocess_pids ||= [] # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      def start_all(app)
        (subclasses || []).each do |subclass|
          process_id = fork do
            instance = subclass.new
            instance.app = app
            app.logger.info "Starting subprocess #{subclass}"
            instance.run
          end
          @subprocess_pids << process_id
          Process.detach(process_id)
        end
      end

      def kill_all
        return if !@subprocess_pids || @subprocess_pids.empty?
        @subprocess_pids.each do |spid|
          begin
            Process.kill('TERM', spid)
          rescue Errno::ESRCH, Errno::EPERM # rubocop:disable Lint/HandleExceptions
            # The list might contain some stale pids, if any of subprocesses terminated early
          end
        end
      end
    end
  end
end
