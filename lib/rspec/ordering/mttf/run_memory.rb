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
          construct_results(group)
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
          new_results = group.examples.each_with_object({}) do |example, object|
            object[example.id] = ExampleResultData.from_example(example)
          end

          unless new_results.empty?
            run_results.merge!(new_results)
            run_results[group.id] = if run_results[group.id]
              [run_results[group.id], new_results.values.min].min
            else
              new_results.values.min
            end
          end

          unless group.top_level?
            run_results[group.superclass.id] = if run_results[group.superclass.id]
              [run_results[group.superclass.id], run_results[group.id]].min
            else
              run_results[group.id]
            end
          end
          run_results
        end

        attr_reader :store, :run_results
      end
    end
  end
end
