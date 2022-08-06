RSpec.describe RSpec::Ordering::Mttf::ExampleResultData do
  include_context "Example Tests"

  describe ".from_example" do
    it "saves status" do
      subject = described_class.from_example(passing_example)
      expect(subject.status).to eq(:passed)
    end

    it "saves last_failed_date and last_run_date" do
      failing_result_data = described_class.from_example(failing_example)
      passing_result_data = described_class.from_example(passing_example)

      expect(failing_result_data.last_failed_date).to eq(current_date)
      expect(failing_result_data.last_run_date).to eq(current_date)
      expect(failing_result_data.last_run_date).to eq(current_date)
      expect(passing_result_data.last_failed_date).to be_nil
    end

    it "preserves last_failed_date for a failing test that now passes" do
      example = passing_example
      example.metadata[:last_failed_date] = Date.today
      expect(described_class.from_example(example).last_failed_date).to eq(Date.today)
    end
  end

  describe "comparing by run time" do
    it "runs the faster test first, all else being equal" do
      group = RSpec.describe "group" do
        it "passes" do
          expect(2).to eq(2)
        end

        it "also passes" do
          expect(1).to eq(1)
        end
      end
      group.run
      faster, slower = group.examples
      faster.execution_result.run_time = 1
      slower.execution_result.run_time = 2

      results = RSpec::Ordering::Mttf::RunResults.new
      results.record_group(group)
      results.annotate_example(faster)
      results.annotate_example(slower)
      faster_result = described_class.from_example_metadata(faster)
      slower_result = described_class.from_example_metadata(slower)

      expect(faster_result).to be < slower_result
    end
  end

  context "when one of the examples was not run" do
    # This can happen when we exit early. It only matters for
    # recording group results, not ordering. We don't want to
    # record the not-run example as the result for the group.
    it "means the run one is less" do
      run_group = RSpec.describe "group" do
        it "will be run" do
          expect(2).to eq(2)
        end
      end

      not_run_group = RSpec.describe "not run group" do
        it "will not be run" do
          expect(2).to eq(2)
        end
      end

      run_group.run
      run_result = described_class.from_example(run_group.examples.first)
      not_run_result = described_class.from_example(not_run_group.examples.first)
      expect(run_result).to be < not_run_result
      expect(not_run_result).to be > run_result
    end
  end
end
