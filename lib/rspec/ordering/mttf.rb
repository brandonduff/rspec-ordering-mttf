# frozen_string_literal: true

require_relative "mttf/version"
require_relative "mttf/run_results"
require_relative "mttf/run_memory"
require_relative "mttf/orderer"
require_relative "mttf/example_result_data"
require "ostruct"
require "yaml/store"

module RSpec
  module Ordering
    module Mttf
      def self.configure(config, current_date: Date.today, previous_run_data: ".rspec-run-data.store")
        run_memory = RunMemory.new(previous_run_data)
        config.add_setting :current_date
        config.current_date = current_date
        config.register_ordering(:global, Orderer.new(run_memory))
        config.reporter.register_listener(run_memory, :example_group_finished)
        config.reporter.register_listener(run_memory, :stop)
      end
    end
  end
end
