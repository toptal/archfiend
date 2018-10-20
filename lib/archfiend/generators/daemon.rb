require 'active_support/inflector'
require 'thor'

module Archfiend
  module Generators
    class Daemon < Thor::Group
      include Thor::Actions

      argument :daemon_name

      # @return Path to templates, used by Thor
      def self.source_root
        File.join(File.dirname(__FILE__), 'daemon', 'templates')
      end

      # Creates a new daemon
      def create
        # Init phase, creating directory structure and applying templates
        extensions.run_with_init_callbacks do
          create_from_templates
        end
        # Exec phase, running any due setup
        extensions.run_with_exec_callbacks do
          bundle_install unless skip_bundle_install?
        end
      end

      no_commands do
        # @param source [String] relative path to the template to be processed
        # @return [String] the evaluated template contents
        def processed_template_contents(source)
          context = instance_eval('binding')
          source  = File.expand_path(find_in_source_paths(source))
          CapturableERB.new(::File.binread(source), nil, '-', '@output_buffer').tap do |erb|
            erb.filename = source
          end.result(context)
        end

        # @return [Pathname] The absolute path of the newly created daemon
        def daemon_destination_dir
          Pathname.new(File.expand_path(File.join(Dir.pwd, daemon_name)))
        end

        # @return [Pathname] Path from which Archfiend was started
        def current_dir
          Pathname.new(File.expand_path(Dir.pwd))
        end

        def daemon_path
          Pathname.new(daemon_name)
        end
      end

      private

      def generator_options
        @generator_options ||= Options.new(args)
      end

      def extensions
        @extensions ||= Extensions.new(generator_options, self, 'daemon')
      end

      def create_from_templates
        %w[readme rakefile gemfile app bin config_directory db lib log spec tmp rubocop].each { |action| __send__(action) }
      end

      def camelized_daemon_name
        @camelized_daemon_name ||= daemon_name.camelize
      end

      # @return Relative path to this gem, to be used in the Gemfile
      def relative_archfiend_path
        gem_dir = Pathname.new(File.expand_path(File.join('..', '..', '..'), __dir__))

        gem_dir.relative_path_from(daemon_destination_dir)
      end

      def readme
        template 'README.md', daemon_path.join('Readme.md')
      end

      def rakefile
        template 'Rakefile', daemon_path.join('Rakefile')
      end

      def gemfile
        template 'Gemfile', daemon_path.join('Gemfile')
      end

      def app
        directory 'app', daemon_path.join('app')
      end

      def bin
        directory 'bin', daemon_path.join('bin')

        chmod daemon_path.join('bin', 'start'), 'a+x'
        chmod daemon_path.join('bin', 'console'), 'a+x'
      end

      def config_directory
        directory 'config', daemon_path.join('config')
      end

      def db
        directory 'db', daemon_path.join('db')
      end

      def lib
        directory 'lib', daemon_path.join('lib')
      end

      def log
        directory 'log', daemon_path.join('log')
      end

      def spec
        template '.rspec', daemon_path.join('.rspec')
        directory 'spec', daemon_path.join('spec')
      end

      def rubocop
        template '.rubocop.yml', daemon_path.join('.rubocop.yml')
      end

      def tmp
        empty_directory daemon_path.join('tmp')
      end

      def bundle_install
        if defined? Bundler
          Bundler.with_clean_env do
            inside daemon_name do
              run 'bundle install'
            end
          end
        else
          inside daemon_name do
            run 'bundle install'
          end
        end
      end

      def skip_bundle_install?
        false
      end
    end
  end
end
