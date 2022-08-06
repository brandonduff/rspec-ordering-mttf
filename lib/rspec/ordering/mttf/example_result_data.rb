module RSpec
  module Ordering
    module Mttf
      class ExampleResultData
        include Comparable

        def self.from_example(example)
          last_failed_date = if example.execution_result.status == :failed
            RSpec.configuration.current_date
          else
            example.metadata[:last_failed_date]
          end
          new(status: example.execution_result.status,
            last_failed_date: last_failed_date,
            last_run_date: RSpec.configuration.current_date,
            run_time: example.execution_result.run_time)
        end

        def self.from_example_metadata(example)
          metadata = example.metadata
          new(status: metadata[:status],
            last_failed_date: metadata[:last_failed_date],
            last_run_date: metadata[:last_run_date],
            run_time: metadata[:last_run_time])
        end

        def self.add_examples_to_group_results(examples, group_results)
          examples = Array(examples)
          summed_run_time = examples.map(&:run_time).compact.sum
          smallest_result = [group_results, examples.min].compact.min

          new(
            status: smallest_result.status,
            last_failed_date: smallest_result.last_failed_date,
            last_run_date: smallest_result.last_run_date,
            run_time: (group_results&.run_time || 0) + summed_run_time
          )
        end

        def initialize(status:, last_failed_date:, last_run_date:, run_time:)
          @status = status
          @last_failed_date = last_failed_date
          @last_run_date = last_run_date
          @run_time = run_time
        end

        attr_accessor :status, :last_failed_date, :last_run_date, :run_time

        def <=>(other)
          if last_run_date.nil?
            -1
          elsif other.last_run_date.nil?
            1
          elsif last_failed_date.nil? && !other.last_failed_date.nil?
            1
          elsif other.last_failed_date.nil? && !last_failed_date.nil?
            -1
          elsif other.last_failed_date && last_failed_date &&
              other.last_failed_date != last_failed_date
            other.last_failed_date <=> last_failed_date
          elsif run_time && !other.run_time
            -1
          elsif !run_time && other.run_time
            1
          else
            run_time <=> other.run_time
          end
        end

        def members
          [:status, :last_failed_date, :last_run_date, :run_time]
        end
      end
    end
  end
end
