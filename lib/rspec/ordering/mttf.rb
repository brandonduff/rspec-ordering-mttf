# frozen_string_literal: true

require_relative "mttf/version"

RSpec.configuration.add_setting :current_date

module RSpec
  module Ordering
    module Mttf
      class Orderer
        def order(items)
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
      end
      require "ostruct"
      require "yaml/store"

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
          end
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
