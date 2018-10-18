module Archfiend
  module Generators
    class Extensions
      PHASES = %i[init exec].freeze
      CALLBACK_TYPES = %i[before after].freeze

      # @param generator_options [Archfiend::Generators::Options] Options, source of potential extensions
      # @param action_context [Thor::Group] Contex of the extended action/group of actions
      # @param generator_name [String] Underscore form name of the generator, ex. daemon
      def initialize(generator_options, action_context, generator_name)
        @generator_options = generator_options
        @action_context = action_context
        @generator_name = generator_name

        @extensions = activate_extensions
        expose_extensions
      end

      def run_with_init_callbacks
        run_callback(:init, :before)

        yield unless skip_default_action?(:init)

        run_callback(:init, :after)
      end

      def run_with_exec_callbacks
        run_callback(:exec, :before)

        yield unless skip_default_action?(:exec)

        run_callback(:exec, :after)
      end

      private

      def skip_default_action?(phase)
        generator_extensions.any? do |ge|
          method_name = "skip_default_#{phase}_action?"
          ge.respond_to?(method_name) && ge.public_send(method_name)
        end
      end

      def run_callback(phase, callback_type)
        fail(ArgumentError, "Unsupported phase #{phase}") unless PHASES.include?(phase)
        fail(ArgumentError, "Unsupported callback_type #{callback_type}") unless CALLBACK_TYPES.include?(callback_type)

        callback_action = [callback_type, phase].join('_')
        generator_extensions.select { |ge| ge.respond_to?(callback_action) }.each { |ge| ge.public_send(callback_action) }
      end

      def run_before_create_extensions
        generator_extensions.select { |ge| ge.respond_to?(:before_create) }.each(&:before_create)
      end

      def run_after_create_extensions
        generator_extensions.select { |ge| ge.respond_to?(:after_create) }.each(&:after_create)
      end

      def generator_extensions
        @generator_extensions ||= @extensions.map do |extension_module|
          next unless extension_module.const_defined?(generator_extensions_class_name)

          extension_klass = extension_module.const_get(generator_extensions_class_name)
          next if extension_klass.respond_to?(:target_generator_name) && extension_klass.target_generator_name != @generator_name

          extension_klass.new(@action_context, @generator_options)
        end.compact
      end

      def generator_extensions_class_name
        "Generators::#{@generator_name.camelize}Extensions" # example: Generators::DaemonExtensions
      end

      def expose_extensions # rubocop:disable Metrics/AbcSize
        generator_extensions.each do |generator_extension|
          exposed_name = if generator_extension.respond_to?(:exposed_name)
                           generator_extension.exposed_name
                         else
                           generator_extension.class.name.split(':').first.underscore
                         end

          if @action_context.respond_to?(exposed_name)
            puts "Extension's exposed_name #{exposed_name.inspect} conflicts with existing method defined in #{@action_context.method(exposed_name).source_location}."
            puts "Please define a method #{generator_extension.class.name}#exposed_name with some other value."
            exit 1
          end

          @action_context.instance_variable_set("@#{exposed_name}", generator_extension)
          @action_context.class.attr_reader(exposed_name)
        end
      end

      def activate_extensions # rubocop:disable Metrics/AbcSize
        extensions = []

        @generator_options.extensions.each do |extension|
          begin
            Kernel.gem(extension)
            Kernel.require(extension)
          rescue LoadError => e
            puts "Unable to load requested extension gem #{extension}, aborting"
            puts e.inspect.to_s
            exit 1
          end
          module_name = extension.camelize
          if Object.const_defined?(module_name)
            extensions << Object.const_get(module_name)
            puts "Activated extension gem #{module_name}"
          else
            puts "Failed to recognize extension module #{module_name} in gem #{extension}, aborting"
            exit 1
          end
        end

        extensions
      end
    end
  end
end
