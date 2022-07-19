# frozen_string_literal: true

require_relative "mttf/version"
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

      class Orderer
        def initialize(memory)
          @memory = memory
        end

        def order(items)
          items.each do |example|
            if (example_memory = memory.read[example.id])
              example.metadata[:last_run_date] ||= example_memory.last_run_date
              example.metadata[:last_failed_date] ||= example_memory.last_failed_date
            end
          end

          items.sort_by do |example|
            ExampleResultData.from_example_metadata(example)
          end
        end

        private

        attr_reader :memory
      end

      class RunMemory
        def initialize(filename)
          @store = YAML::Store.new(filename)
        end

        def example_group_finished(summary_notification)
          write(summary_notification.group)
        end

        def write(group)
          existing = read
          store.transaction do
            store["results"] = existing.merge(construct_results(group))
          end
        end

        def read
          store.transaction(true) do
            store["results"]
          end || {}
        end

        private

        def construct_results(group)
          result = group.examples.each_with_object({}) do |example, object|
            object[example.id] = ExampleResultData.from_example(example)
          end
          result[group.id] = result.values.min
          result
        end

        attr_reader :store
      end

      ExampleResultData = Struct.new(:status, :last_failed_date, :last_run_date, keyword_init: true) do
        include Comparable

        def self.from_example(example)
          last_failed_date = example.execution_result.status == :failed ? RSpec.configuration.current_date : example.metadata[:last_failed_date]
          new(status: example.execution_result.status, last_failed_date: last_failed_date, last_run_date: RSpec.configuration.current_date)
        end

        def self.from_example_metadata(example)
          metadata = example.metadata
          new(status: metadata[:status], last_failed_date: metadata[:last_failed_date], last_run_date: metadata[:last_run_date])
        end

        def <=>(other)
          if last_run_date.nil?
            -1
          elsif other.last_run_date.nil?
            1
          elsif last_failed_date.nil?
            1
          elsif other.last_failed_date.nil?
            -1
          else
            other.last_failed_date <=> last_failed_date
          end
        end
      end
    end
  end
end
