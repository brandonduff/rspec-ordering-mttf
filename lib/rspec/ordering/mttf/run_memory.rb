module RSpec
  module Ordering
    module Mttf
      class RunMemory
        def initialize(filename)
          @store = YAML::Store.new(filename)
          @run_results = RunResults.new
        end

        def example_group_finished(summary_notification)
          collect_result(summary_notification.group)
        end

        def stop(_reporter)
          write
        end

        def read
          store.transaction(true) do
            RunResults.new(store["results"] || {})
          end
        end

        private

        def write
          existing = read
          store.transaction do
            store["results"] = existing.merge(run_results)
          end
        end

        def collect_result(group)
          run_results.record_group(group)
        end

        attr_reader :store, :run_results
      end
    end
  end
end
