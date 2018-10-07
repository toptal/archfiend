require 'logger'
require 'oj'

module Archfiend
  class Logging
    class << self
      # @param environment [String|Symbol] Current running environment, ex. :development
      # @param log_directory [String,Pathname] Directory in which the logfile is supposed to live
      # @param quiet [Boolean] Whether the STDOUT development output should be suppressed
      # @return [MultiLogger] A multiplexer for up to two loggers
      def create(environment, log_directory, quiet = false)
        environment = environment.to_sym
        loggers = [file_logger(environment, log_directory)]
        loggers << stdio_logger if environment == :development && !quiet

        MultiLogger.new(*loggers)
      end

      private

      def file_logger(environment, log_directory)
        log_name = File.join(log_directory, "#{environment}.log")
        file_logger = Logger.new(log_name, 'daily')
        file_logger.formatter = JSONFormatter.new
        file_logger
      end

      def stdio_logger
        stdout_io = IO.try_convert(STDOUT)
        stdout_io.sync = true
        stdout_logger = Logger.new(stdout_io)

        stdout_logger.formatter = DefaultFormatter.new
        stdout_logger
      end
    end
  end
end
