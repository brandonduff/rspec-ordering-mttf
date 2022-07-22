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

        def collect_result(group)
          new_results = construct_new_results(group)

          unless new_results.empty?
            run_results.merge!(new_results)
            update_group_result(group, new_results)
          end

          unless group.top_level?
            update_parent_result(group)
          end
        end

        def update_parent_result(group)
          run_results[group.superclass.id] = if run_results[group.superclass.id]
            [run_results[group.superclass.id], run_results[group.id]].min
          else
            run_results[group.id]
          end
        end

        def update_group_result(group, new_results)
          run_results[group.id] = if run_results[group.id]
            [run_results[group.id], new_results.values.min].min
          else
            new_results.values.min
          end
        end

        def construct_new_results(group)
          group.examples.each_with_object({}) do |example, object|
            object[example.id] = ExampleResultData.from_example(example)
          end
        end

        attr_reader :store, :run_results
      end
    end
  end
end
