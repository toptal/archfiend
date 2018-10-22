module Archfiend
  module String
    module Underscore
      # @return [String] String in the lowercase underscore format
      def underscore
        return self unless /[A-Z-]|::/.match?(self)

        word = gsub('::'.freeze, '/'.freeze)
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
        word.tr!('-'.freeze, '_'.freeze)
        word.downcase!
        word
      end
    end
  end
end

String.include(Archfiend::String::Underscore) unless ''.respond_to?(:underscore)
