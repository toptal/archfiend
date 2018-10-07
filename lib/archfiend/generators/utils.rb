module Archfiend
  module Generators
    module Utils
      class << self
        # Methods borrowed from Bundler
        # source: bundler/lib/bundler/shared_helpers.rb
        def find_file(*names)
          search_up(*names) do |filename|
            return filename if File.file?(filename)
          end
        end

        def find_directory(*names)
          search_up(*names) do |dirname|
            return dirname if File.directory?(dirname)
          end
        end

        private

        def search_up(*names)
          previous = nil
          current  = File.expand_path(Pathname.pwd).untaint

          until !File.directory?(current) || current == previous
            names.each do |name|
              filename = File.join(current, name)
              yield filename
            end
            previous = current
            current = File.expand_path('..', current)
          end
        end
      end
    end
  end
end
