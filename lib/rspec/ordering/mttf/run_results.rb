module RSpec
  module Ordering
    module Mttf
      class RunResults
        def initialize(hash = {})
          @results = hash || {}
        end

        def merge(other)
          @results.merge(other.results)
        end

        def record_group(group)
          record_examples(group)
          update_group(group, @results.values.min)
          update_group(group.superclass, self[group]) unless group.top_level?
        end

        def annotate_example(example)
          if (example_run_result = self[example])
            example.metadata[:last_run_date] ||= example_run_result.last_run_date
            example.metadata[:last_failed_date] ||= example_run_result.last_failed_date
          end
        end

        def [](example)
          @results[example.id]
        end

        protected

        attr_reader :results

        private

        def []=(example, value)
          @results[example.id] = value
        end

        def update_group(group, new_value)
          results_for_group = self[group]
          self[group] = if results_for_group
            [results_for_group, new_value].min
          else
            new_value
          end
        end

        def record_examples(group)
          group.examples.each do |example|
            self[example] = ExampleResultData.from_example(example)
          end
        end
      end
    end
  end
end
