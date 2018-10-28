module Archfiend
  class Daemon
    DEV_NULL = '/dev/null'.freeze

    class << self
      def daemonize(pid_file:, log_file:, app_name:, app_env:)
        Process.daemon(nil, true) # Don't close descriptors
        handle_pid_file(pid_file)
        close_io
        redirect_std_io(log_file)
        set_process_title(app_name, app_env)
        srand
      end

      def set_process_title(app_name, app_env)
        Process.setproctitle "#{app_name} (#{app_env})"
      end

      def handle_pid_file(pid_file)
        if File.exist?(pid_file)
          msg = "Pid file #{pid_file} already exists, the daemon is already running or " \
            "didn't shut down properly. \nRemove the pid file and try again."
          Process.abort(msg)
        end

        daemon_pid = Process.pid
        begin
          File.open(pid_file, 'w') { |f| f.puts daemon_pid }
        rescue
          msg = "Pid file creation failed, no permissions to write to #{pid_file}."
          Process.abort(msg)
        end
        at_exit do
          next unless Process.pid == daemon_pid

          begin
            File.unlink(pid_file)
          rescue
            nil
          end
        end
      end

      def redirect_std_io(log_file)
        redirect_stdin
        redirect_stdout(log_file)
        redirect_stderr
      end

      def close_io
        ObjectSpace.each_object(IO) do |io|
          next if [$stdin, $stdout, $stderr].include?(io)

          begin
            io.close
          rescue
            nil
          end
        end
        3.upto(8192) do |i|
          begin
            IO.for_fd(i).close
          rescue
            nil
          end
        end
      end

      private

      def redirect_stdin
        $stdin.reopen DEV_NULL
      rescue Exception # rubocop:disable Lint/RescueException
        Process.abort('Failed to redirect stdin to dev null')
      end

      def redirect_stdout(logfile_name)
        $stdout.reopen logfile_name, 'a'
        File.chmod(0o644, logfile_name)
        $stdout.sync = true
      end

      def redirect_stderr
        $stderr.reopen $stdout
        $stderr.sync = true
      rescue ::Exception # rubocop:disable Lint/RescueException
        Process.abort('Failed to redirect stderr to stdout')
      end
    end
  end
end
