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
        config.reporter.register_listener(run_memory, :dump_summary)
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

          items.sort do |a, b|
            if a.metadata[:last_run_date].nil?
              -1
            elsif b.metadata[:last_run_date].nil?
              1
            elsif a.metadata[:last_failed_date].nil?
              1
            elsif b.metadata[:last_failed_date].nil?
              -1
            else
              b.metadata[:last_failed_date] <=> a.metadata[:last_failed_date]
            end
          end
        end

        private

        attr_reader :memory
      end

      class RunMemory
        def initialize(filename)
          @store = YAML::Store.new(filename)
        end

        def dump_summary(summary_notification)
          write(summary_notification.examples)
        end

        def write(examples)
          store.transaction do
            store["results"] = construct_results(examples)
          end
        end

        def read
          store.transaction(true) do
            store["results"]
          end || {}
        end

        private

        def construct_results(examples)
          examples.each_with_object({}) do |example, object|
            object[example.id] = ExampleResultData.from_example(example)
          end
        end

        attr_reader :store
      end

      ExampleResultData = Struct.new(:status, :last_failed_date, :last_run_date, keyword_init: true) do
        def self.from_example(example)
          last_failed_date = example.execution_result.status == :failed ? RSpec.configuration.current_date : example.metadata[:last_failed_date]
          new(status: example.execution_result.status, last_failed_date: last_failed_date, last_run_date: RSpec.configuration.current_date)
        end
      end
    end
  end
end
