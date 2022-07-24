require "ostruct"

describe RSpec::Ordering::Mttf::ExampleResultData do
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
      date = Date.today
      faster = OpenStruct.new(metadata: {})
      faster.metadata[:last_failed_date] = date
      faster.metadata[:last_run_date] = date
      faster.metadata[:run_time] = 1

      slower = OpenStruct.new(metadata: {})
      slower.metadata[:last_failed_date] = date
      slower.metadata[:last_run_date] = date
      slower.metadata[:run_time] = 2

      faster_result = described_class.from_example_metadata(faster)
      slower_result = described_class.from_example_metadata(slower)

      expect(faster_result).to be < slower_result
    end

    it "runs the faster test first, all else being equal two" do
      date = Date.today
      faster = OpenStruct.new(metadata: {})
      faster.metadata[:last_failed_date] = date
      faster.metadata[:last_run_date] = date
      faster.metadata[:run_time] = 1

      slower = OpenStruct.new(metadata: {})
      slower.metadata[:last_failed_date] = date
      slower.metadata[:last_run_date] = date
      slower.metadata[:run_time] = 2

      faster_result = described_class.from_example_metadata(faster)
      slower_result = described_class.from_example_metadata(slower)

      expect(faster_result).to be < slower_result
    end
  end
end
