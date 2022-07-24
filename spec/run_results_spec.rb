require "rspec"

describe RSpec::Ordering::Mttf::RunResults do
  include_context "Example Tests"

  it "annotates with last run time" do
    example = passing_example
    subject.record_group(sample_group)
    subject.annotate_example(example)
    expect(example.metadata[:last_run_time]).to eq(example.execution_result.run_time)
  end

  it "keeps groups separate" do
    failing_group = RSpec.describe "failing group" do
      it "fails" do
        expect(2).to eq(3)
      end
    end

    passing_group = RSpec.describe "passing group" do
      it "passes" do
        expect(2).to eq(2)
      end
    end
    failing_group.run
    passing_group.run

    subject.record_group(failing_group)
    subject.record_group(passing_group)

    expect(subject[passing_group].status).to eq(:passed)
  end
end
