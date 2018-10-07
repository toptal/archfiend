require 'thor'

module Archfiend
  class CLI < Thor
    package_name "Archfiend (#{Archfiend::VERSION})"

    register(Generators::Daemon, 'new', 'new DAEMON_NAME', 'Bootstraps a new daemon named DAEMON_NAME')
  end
end
