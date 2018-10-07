require 'timecop'

RSpec.configure do |config|
  config.around(:each, freeze: true) do |example|
    # Default is current time rounded to seconds
    time = Time.zone.at(Time.now.to_i)
    Timecop.freeze(time) { example.run }
  end
end
