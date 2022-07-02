# frozen_string_literal: true

require_relative "mttf/version"

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

        ExampleResultData = Struct.new(:status, keyword_init: true)

        def construct_results(examples)
          examples.each_with_object({}) do |example, object|
            object[example.id] = ExampleResultData.new(status: example.execution_result.status)
          end
        end

        attr_reader :store
      end
    end
  end
end
