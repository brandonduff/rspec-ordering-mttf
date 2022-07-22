module RSpec
  module Ordering
    module Mttf
      class RunMemory
        def initialize(filename)
          @store = YAML::Store.new(filename)
          @run_results = {}
        end

        def example_group_finished(summary_notification)
          collect_result(summary_notification.group)
        end

        def stop(_reporter)
          write
        end

        def collect_result(group)
          run_results.merge!(construct_results(group))
        end

        def read
          store.transaction(true) do
            store["results"]
          end || {}
        end

        private

        def write
          existing = read
          store.transaction do
            store["results"] = existing.merge(run_results)
          end
        end

        def construct_results(group)
          result = group.examples.each_with_object({}) do |example, object|
            object[example.id] = ExampleResultData.from_example(example)
          end
          result[group.id] = result.values.min
          result
        end

        attr_reader :store, :run_results
      end
    end
  end
end
