require "rspec"

describe RSpec::Ordering::Mttf::RunResults do
  include_context "Example Tests"

  describe "last run time" do
    it "annotates with last run time" do
      example = passing_example
      subject.record_group(sample_group)
      subject.annotate_example(example)
      expect(example.metadata[:last_run_time]).to eq(example.execution_result.run_time)
    end

    it "adds up example run times for the group" do
      passing_example.execution_result.run_time = 1
      failing_example.execution_result.run_time = 2
      subject.record_group(sample_group)
      expect(subject[sample_group].run_time).to eq(3)
    end

    it "adds up group run time to parent groups" do
      first_example, second_example, first_child, second_child = nil
      parent = RSpec.describe "parent group" do
        first_child = describe "child group" do
          first_example = it "is a test" do
            expect(1).to eq(1)
          end
        end

        second_child = describe "another child group" do
          second_example = it "is another test" do
            expect(2).to eq(2)
          end
        end
      end

      parent.run
      first_example.execution_result.run_time = 1
      second_example.execution_result.run_time = 2

      subject.record_group(first_child)
      subject.record_group(second_child)
      subject.record_group(parent)

      expect(subject[parent].run_time).to eq(3)
    end
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

  it "can record a group that is partially run" do
    group = RSpec.describe "group" do
      it "runs" do
        expect(2).to eq(2)
        RSpec.world.wants_to_quit = true
      end

      it "doesn't run" do
        expect(2).to eq(3)
      end
    end
    group.run

    subject.record_group(group)

    expect(subject[group].status).to eq(:passed)
  end
end
