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
          new_examples = record_examples(group)
          update_group(group, new_examples.min)
          self[group].run_time += new_examples.sum(&:run_time)
          unless group.top_level?
            update_group(group.superclass, self[group])
            self[group.superclass].run_time += self[group].run_time
          end
        end

        def annotate_example(example)
          if (example_run_result = self[example])
            example.metadata[:last_run_date] = example_run_result.last_run_date
            example.metadata[:last_failed_date] = example_run_result.last_failed_date
            example.metadata[:last_run_time] = example_run_result.run_time
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
          return unless new_value

          smallest_group = [self[group], new_value].compact.min

          self[group] = ExampleResultData.new(
            status: smallest_group.status,
            last_failed_date: smallest_group.last_failed_date,
            last_run_date: smallest_group.last_run_date,
            run_time: self[group] ? self[group].run_time : 0
          )
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
