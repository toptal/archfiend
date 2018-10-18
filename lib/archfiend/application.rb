module Archfiend
  class Application
    extend ::Forwardable

    def_delegators :utils, :logger, :env, :name

    # The main application entry point, it starts up all the subthreads, all the subprocesses,
    # registers the exit handler and then it blocks the execution.
    def run
      logger.info 'Starting up'

      setup

      ThreadLoop.start_all(self)
      SubprocessLoop.start_all(self)

      run_clockwork

      # Setup after subprocesses are created, so the handler is not copied to them
      setup_cleanup
      loop { sleep 1 }
    end

    def setup
      return if @already_setup

      setup_timezone
      setup_settings
      setup_logger
      setup_activerecord
      setup_debug

      run_initializers
      require_app_classes

      @already_setup = true
    end

    private

    def run_initializers
      Dir[utils.root.join('config', 'initializers', '**', '*.rb')].sort.each do |ruby_file|
        load ruby_file
      end
    end

    def require_app_classes
      rb_pattern = utils.root.join('app', '**', '*.rb')
      Dir[rb_pattern].each { |file_name| require file_name }
    end

    def setup_activerecord
      # TODO: ensure connection timezone is correct

      yaml_text = ERB.new(IO.read(utils.root.join('config', 'database.yml'))).result
      ::ActiveRecord::Base.configurations = YAML.load(yaml_text) # rubocop:disable Security/YAMLLoad
      ::ActiveRecord::Base.establish_connection(env.to_sym)
      ::ActiveRecord::Base.logger = utils.logger if %w[development test].include?(env)
    end

    def setup_timezone
      Time.zone_default = ActiveSupport::TimeZone['UTC']
    end

    def setup_settings
      ::Config.load_and_set_settings(::Config.setting_files(utils.root.join('config'), env))
    end

    # Starts a new thread that runs tasks defined in the Clockwork module.
    def run_clockwork
      return unless self.class.const_defined?('Clockwork')

      th = Thread.new do
        ::Clockwork.run
      end
      th[:name] = 'Clockwork'
    end

    POSSIBLE_LOGGER_LEVELS = %i[debug info warn error fatal unknown].freeze
    def setup_logger
      logger_level = Settings.logger&.level
      fail "Please set logger.level setting (#{POSSIBLE_LOGGER_LEVELS.inspect})" unless POSSIBLE_LOGGER_LEVELS.include?(logger_level)

      utils.logger.level = logger_level
      utils.logger.progname = name
    end

    # Registers actions to be performed when the ruby vm exits
    def setup_cleanup
      at_exit do
        utils.logger.info 'Exiting'
        SubprocessLoop.kill_all
      end
    end

    def setup_debug
      return unless Settings.debug&.rbtrace

      require 'rbtrace'
    rescue LoadError => e
      puts 'Settings.debug.rbtrace is true but cannot load the "rbtrace" gem, make sure it is present in Gemfile'
      puts "(#{e})"
      exit 1
    end
  end

  module Utilities
    def logger
      @logger ||= Archfiend::Logging.create(env, root.join('log'))
    end

    def app
      @app ||= const_get('Application').new
    end

    def env
      ENV['APP_ENV'] || ENV['RAILS_ENV'] || 'development'
    end

    # Returns all dependency groups for loading based on:
    # * The App environment;
    # * The environment variable APP_GROUPS;
    # @return [Array<string>] All gem groups that needs to be included for current env
    def groups(*groups)
      groups.unshift(:default, env.to_sym)
      env_groups = ENV['APP_GROUPS'] || ENV['RAILS_GROUPS']
      groups.concat env_groups.to_s.split(',')
      groups.compact!
      groups.uniq!
      groups
    end
  end
end
