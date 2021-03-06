require 'thor'
require 'pathname'
require 'forwardable'
require 'archfiend/version'
require 'archfiend/generators/daemon'
require 'archfiend/generators/options'
require 'archfiend/generators/extensions'
require 'archfiend/generators/utils'
require 'archfiend/core_ext/string/camelize'
require 'archfiend/core_ext/string/underscore'

module Archfiend
  class CLI < Thor
    package_name "Archfiend (#{Archfiend::VERSION})"

    register(Generators::Daemon, 'new', 'new DAEMON_NAME', 'Bootstraps a new daemon named DAEMON_NAME')
  end
end
