# This is a simple matcher that has a subset of functionality of a regular `change` matcher.
# It evaluates the condition block repeatedly, until it's value equals the expected one or the timeout hits.
#
# Example usage:
# ```
#   expect { process_exists?(pid) }.to change_with_timeout { Process.kill(9, pid) }.from(true).to(false)
# ```
module ChangeWithTimeout
  TIMEOUT = 1 # Second
  SAMPLING_RATE = 20 # Times
  DELAY_INTERVAL = TIMEOUT.to_f / SAMPLING_RATE
end

RSpec::Matchers.define :change_with_timeout do
  match do |first_block|
    unless defined?(@from_value) && defined?(@to_value)
      fail 'both from(value) and to(value) have to be chained for change_with_format'
    end

    start_value = @block_arg.call

    unless start_value == @from_value
      @incorrect_from_value = start_value
      return
    end

    first_block.call

    new_value = nil
    ChangeWithTimeout::SAMPLING_RATE.times do
      new_value = @block_arg.call
      return true if new_value == @to_value

      sleep ChangeWithTimeout::DELAY_INTERVAL
    end
    @final_value = new_value
    false
  end

  failure_message do |_actual|
    if defined?(@incorrect_from_value)
      "expected evaluated block value to have initially been #{@from_value}, but was #{@incorrect_from_value}"
    elsif @final_value == @from_value
      "expected evaluated block value to have changed from #{@from_value}, but did not change"
    else
      "expected evaluated block value to have changed to #{@to_value}, but is now #{@final_value}"
    end
  end

  chain :from do |from_value|
    @from_value = from_value
  end

  chain :to do |to_value|
    @to_value = to_value
  end

  supports_block_expectations
end
