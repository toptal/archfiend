require 'logger'

module Archfiend
  class Logging
    class << self
      DEFAULT_FORMATTERS = {
        file: 'JSONFormatter',
        stdout: 'DefaultFormatter'
      }.freeze

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
        file_logger.formatter = formatter_from_settings(:file)
        file_logger
      end

      def stdio_logger
        stdout_io = IO.try_convert(STDOUT)
        stdout_io.sync = true
        stdout_logger = Logger.new(stdout_io)

        stdout_logger.formatter = formatter_from_settings(:stdout)
        stdout_logger
      end

      # @param type [Symbol] :file or :stdout
      # @return [Logging::BaseFormatter] a formatter instance
      def formatter_from_settings(type)
        formatter_name = Settings.logger.dig(:formatter, type) || DEFAULT_FORMATTERS.fetch(type)

        instantiate_formatter(formatter_name)
      end

      def instantiate_formatter(name)
        return Archfiend::Logging.const_get(name).new if Archfiend::Logging.const_defined?(name)

        possible_formatter_source = File.join('logging', name.underscore)
        require_relative(possible_formatter_source)

        Archfiend::Logging.const_get(name).new
      rescue StandardError, LoadError => e
        puts "Unable to load log formatter #{name.inspect}."
        puts "\nException: #{e.message}"
        exit 1
      end
    end
  end
end
