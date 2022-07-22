module RSpec
  module Ordering
    module Mttf
      class Orderer
        def initialize(memory)
          @memory = memory
        end

        def order(items)
          items.each do |example|
            if (example_memory = memory.read[example.id])
              example.metadata[:last_run_date] ||= example_memory.last_run_date
              example.metadata[:last_failed_date] ||= example_memory.last_failed_date
            end
          end

          items.sort_by do |example|
            ExampleResultData.from_example_metadata(example)
          end
        end

        private

        attr_reader :memory
      end
    end
  end
end
