require 'time'
require 'bundler/setup'
require 'archfiend'
require 'archfiend/cli'
require 'tmpdir'

require_relative 'support/change_with_timeout_matcher'

ENV['APP_ENV'] = 'test'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
