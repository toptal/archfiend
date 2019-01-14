require 'json'

module Checks
  class Footprint
    def check(name, require_string, max_rss, max_ms)
      puts "Checking footprint of #{name}"

      summary_entry = footprint_json(require_string).find { |entry| entry['name'] == require_string }
      unless summary_entry
        puts "Failed finding the summary entry of #{require_string} in #{footprint_json.inspect}"
        exit 1
      end

      check_rss(name, summary_entry, max_rss)
      check_time(name, summary_entry, max_ms)
    end

    private

    def check_rss(name, entry, max)
      puts "Archfiend #{name} RSS #{entry['rss']['mean']}"
      return if entry['rss']['mean'] < max

      puts "Exceeds maximal allowed #{max}"
      exit 1
    end

    def check_time(name, entry, max)
      puts "Archfiend #{name} require time #{entry['time']['mean']}ms"
      return if entry['time']['mean'] < max

      puts "Exceeds maximal allowed #{max}"
      exit 1
    end

    def run_checker(require_string)
      `RUBYLIB=./lib analyze_requires -r -f json -n 100 archfiend #{require_string}`
    end

    def footprint_json(require_string)
      JSON.parse(run_checker(require_string))
    end
  end
end
