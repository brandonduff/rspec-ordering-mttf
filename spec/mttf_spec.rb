require "date"
require "rspec/core/sandbox"
require "rspec/ordering/mttf"

describe RSpec::Ordering::Mttf do
  it "has a version" do
    expect(described_class::VERSION).to eq("0.1.0")
  end

  def run_with_ordering_log
    ordering_log = []
    RSpec::Core::Sandbox.sandboxed do |config|
      config.register_ordering(:global, RSpec::Ordering::Mttf::Orderer.new(RSpec::Ordering::Mttf::RunMemory.new("test_results.store")))
      example_group = yield(ordering_log)
      example_group.run
    end
    ordering_log
  end

  describe RSpec::Ordering::Mttf::Orderer do
    it "runs examples that have never been run first" do
      run_order = run_with_ordering_log do |ordering_log|
        RSpec.describe "unordered group" do
          it "runs this one second", last_run_date: Date.today, last_failed_date: Date.today do
            ordering_log << 2
          end

          it "runs this one last", last_run_date: Date.today do
            ordering_log << 3
          end

          it "runs this one first" do
            ordering_log << 1
          end
        end
      end

      expect(run_order).to eq([1, 2, 3])
    end

    it "runs examples that have failed more recently first" do
      run_order = run_with_ordering_log do |ordering_log|
        RSpec.describe "unordered group" do
          it "runs this one second", last_run_date: Date.today, last_failed_date: Date.today - 2 do
            ordering_log << 2
          end

          it "runs this one last", last_run_date: Date.today, last_failed_date: Date.today - 3 do
            ordering_log << 3
          end

          it "runs this one first", last_run_date: Date.today, last_failed_date: Date.today do
            ordering_log << 1
          end
        end
      end

      expect(run_order).to eq([1, 2, 3])
    end
  end

  describe RSpec::Ordering::Mttf::RunMemory do
    subject { described_class.new("test_results.store") }

    after do
      File.delete("test_results.store")
    end

    it "writes and reads examples with status metadata" do
      example_group = sandboxed do |runner|
        example_group = RSpec.describe "examples" do
          it "has some new metadata" do
            expect(2).to eq(2)
          end
        end
        runner.call(example_group)
        example_group
      end

      expect(subject.read[example_group.examples.first.id].status).to eq(:passed)
    end

    it "saves metadata for example groups" do
      group = sandboxed do |runner|
        group = RSpec.describe "some examples" do
          it "passes" do
            expect(2).to eq(2)
          end

          it "fails" do
            expect(2).to eq(1)
          end

          context "nested group" do
            it "passes" do
              expect(2).to eq(2)
            end
          end
        end
        runner.call(group)
        group
      end

      expect(subject.read[group.id].status).to eq(:failed)
      expect(subject.read[group.descendants.last.id].status).to eq(:passed)
    end

    xit "uses the most relevant status from the child example group for the parent" do
      group = sandboxed do |runner|
        group = RSpec.describe "some examples" do
          it "passes" do
            expect(2).to eq(2)
          end

          context "nested group" do
            it "fails" do
              expect(2).to eq(3)
            end
          end
        end
        runner.call(group)
        group
      end
      expect(subject.read[group.id].status).to eq(:failed)
    end

    it "loads metadata from previous runs" do
      last_run_date = last_failed_date = nil
      ordering_log = []
      sandboxed do |runner|
        example_group = RSpec.describe "examples" do
          it "is an example" do |example|
            ordering_log << 1
            expect(2).to eq(2)
            last_run_date = example.metadata[:last_run_date]
          end

          it "is a failed example" do |example|
            ordering_log << 2
            last_failed_date = example.metadata[:last_failed_date]
            expect(2).to eq(1)
          end
        end
        runner.call(example_group)
        runner.call(example_group)
      end
      expect(last_run_date).to eq(Date.new(1993, 10, 3))
      expect(last_failed_date).to eq(Date.new(1993, 10, 3))
      expect(ordering_log).to eq([1, 2, 2, 1])
    end

    def sandboxed
      RSpec::Core::Sandbox.sandboxed do |config|
        config.output_stream = StringIO.new # prevent printing report to $stdout

        RSpec::Ordering::Mttf.configure(config, current_date: Date.new(1993, 10, 3), previous_run_data: "test_results.store")
        yield ->(example_group) { config.with_suite_hooks { config.reporter.report(1) { |reporter| example_group.run(reporter) } } }
      end
    end
  end

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
