module RSpec
  module Ordering
    module Mttf
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
    end
  end
end
