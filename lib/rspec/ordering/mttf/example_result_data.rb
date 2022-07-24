module RSpec
  module Ordering
    module Mttf
      ExampleResultData = Struct.new(:status, :last_failed_date, :last_run_date, :run_time, keyword_init: true) do
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
            run_time: metadata[:run_time])
        end

        def <=>(other)
          if last_run_date.nil?
            -1
          elsif other.last_run_date.nil?
            1
          elsif last_failed_date.nil?
            1
          elsif other.last_failed_date.nil?
            -1
          elsif other.last_failed_date != last_failed_date
            other.last_failed_date <=> last_failed_date
          else
            run_time <=> other.run_time
          end
        end
      end
    end
  end
end
