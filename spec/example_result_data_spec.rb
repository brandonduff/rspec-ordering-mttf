describe RSpec::Ordering::Mttf::ExampleResultData do
  around do |example|
    RSpec::Core::Sandbox.sandboxed do |config|
      config.add_setting :current_date
      config.current_date = Date.new(1993, 10, 3)
      example.run
    end
  end

  it "saves status" do
    subject = described_class.from_example(passing_example)
    expect(subject.status).to eq(:passed)
  end

  it "saves last_failed_date and last_run_date" do
    failing_result_data = described_class.from_example(failing_example)
    passing_result_data = described_class.from_example(passing_example)

    expect(failing_result_data.last_failed_date).to eq(Date.new(1993, 10, 3))
    expect(failing_result_data.last_run_date).to eq(Date.new(1993, 10, 3))
    expect(failing_result_data.last_run_date).to eq(Date.new(1993, 10, 3))
    expect(passing_result_data.last_failed_date).to be_nil
  end

  it "preserves last_failed_date for a failing test that now passes" do
    example = passing_example
    example.metadata[:last_failed_date] = Date.today
    expect(described_class.from_example(example).last_failed_date).to eq(Date.today)
  end

  def passing_example
    sample_examples.last
  end

  def failing_example
    sample_examples.first
  end

  def sample_examples
    group = RSpec.describe "examples" do
      it "should fail" do
        expect(2).to eq(1)
      end

      it "should pass" do
        expect(2).to eq(2)
      end
    end
    group.run
    group.examples
  end
end
