module RSpec
  module Ordering
    module Mttf
      class Orderer
        def initialize(memory)
          @run_results = memory.read
        end

        def order(items)
          items.each do |example|
            run_results.annotate_example(example)
          end

          items.sort_by do |example|
            ExampleResultData.from_example_metadata(example)
          end
        end

        private

        attr_reader :run_results
      end
    end
  end
end
