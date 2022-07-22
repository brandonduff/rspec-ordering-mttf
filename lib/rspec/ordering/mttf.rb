# frozen_string_literal: true

require_relative "mttf/version"
require "run_memory"
require "orderer"
require "example_result_data"
require "ostruct"
require "yaml/store"

module RSpec
  module Ordering
    module Mttf
      def self.configure(config, current_date:, previous_run_data:)
        run_memory = RunMemory.new(previous_run_data)
        config.add_setting :current_date
        config.current_date = current_date
        config.register_ordering(:global, Orderer.new(run_memory))
        config.reporter.register_listener(run_memory, :example_group_finished)
      end
    end
  end
end
