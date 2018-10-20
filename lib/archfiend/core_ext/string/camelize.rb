module Archfiend
  module String
    module Camelize
      # rubocop:disable Style/PerlBackrefs
      # @return [String] String in the camelized format, first letter capital
      def camelize
        string = sub(/^[a-z\d]*/, &:capitalize)
        string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
        string.gsub!('/'.freeze, '::'.freeze)
        string
      end
      # rubocop:enable Style/PerlBackrefs
    end
  end
end

String.include(Archfiend::String::Camelize) unless ''.respond_to?(:camelize)
