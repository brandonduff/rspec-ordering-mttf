module RSpec
  module Ordering
    module Mttf
      class RunResults
        def initialize(hash = {})
          @results = hash
        end

        def merge(other)
          results.merge(other.results)
        end

        def record_group(group)
          new_examples = record_examples(group)
          updated_group_results = update_group(group, new_examples)
          update_group(group.superclass, updated_group_results) unless group.top_level?
        end

        def annotate_example(example)
          if (example_run_result = self[example])
            example.metadata[:last_run_date] = example_run_result.last_run_date
            example.metadata[:last_failed_date] = example_run_result.last_failed_date
            example.metadata[:last_run_time] = example_run_result.run_time
          end
        end

        def [](example)
          results[example.id]
        end

        protected

        attr_reader :results

        private

        def []=(example, value)
          results[example.id] = value
        end

        def update_group(group, new_examples)
          self[group] = ExampleResultData
            .add_examples_to_group_results(new_examples, self[group])
        end

        def record_examples(group)
          group.examples.map do |example|
            self[example] = ExampleResultData.from_example(example)
          end
        end
      end
    end
  end
end
