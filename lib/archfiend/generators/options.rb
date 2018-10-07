require 'ostruct'
require 'optparse'

module Archfiend
  module Generators
    class Options
      extend Forwardable
      SETTINGS_FILE = '.archfiend'.freeze

      def_delegators :@options, :extensions

      def initialize(args)
        default_args = parse_archfiend_file || []
        @options = parse_options(default_args + args)
      end

      private

      def parse_options(args)
        options = OpenStruct.new
        options.extensions = Set.new

        opt_parser = OptionParser.new do |opts|
          opts.on '-e', '--extension EXTENSION_NAME', 'Include the specified Archfiend extension' do |extension_name|
            options.extensions << extension_name
          end
        end

        opt_parser.parse!(args)
        options
      end

      # Look if there is a default settings file in pwd or all the way up and read it
      #
      # @return [Array<String>, nil] A list of options from the options file or nil when no file
      def parse_archfiend_file
        settings_file = Utils.find_file(SETTINGS_FILE)

        return unless settings_file

        unless File.readable?(settings_file)
          puts "Skipping #{settings_file}, not readable"
          return
        end

        puts "Reading #{settings_file} for default options"
        File.read(settings_file).split
      end
    end
  end
end
