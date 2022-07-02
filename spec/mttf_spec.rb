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
      config.register_ordering(:global, RSpec::Ordering::Mttf::Orderer.new)
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

    it "can write examples" do
      example_group = RSpec::Core::Sandbox.sandboxed do
        example_group = RSpec.describe "examples to persist" do
          it "passes" do
            expect(2).to eq(2)
          end

          it "fails" do
            fail("oops i failed")
          end
        end
        example_group.run
        example_group
      end

      examples = example_group.examples
      subject.write(examples)
      expect(subject.read[examples.first.id].status).to eq(:passed)
      expect(subject.read[examples.last.id].status).to eq(:failed)
    end

    it "puts saved data on the example" do
      example_group = RSpec::Core::Sandbox.sandboxed do |config|
        config.output_stream = StringIO.new # prevent printing report to $stdout
        config.reporter.register_listener(described_class.new("test_results.store"), :dump_summary)
        example_group = RSpec.describe "examples" do
          it "has some new metadata" do
            expect(2).to eq(2)
          end
        end
        config.reporter.report(1) { |reporter| example_group.run(reporter) }
        example_group
      end
      expect(subject.read[example_group.examples.first.id].status).to eq(:passed)
    end
  end

  describe RSpec::Ordering::Mttf::ExampleResultData do
    it "saves status" do
      RSpec::Core::Sandbox.sandboxed do
        group = RSpec.describe "examples" do
          it "should pass" do
            expect(2).to eq(2)
          end
        end
        group.run
        example = group.examples.first
        subject = described_class.from_example(example)

        expect(subject.status).to eq(:passed)
      end
    end

    it "saves last_failed_date and last_run_date" do
      RSpec::Core::Sandbox.sandboxed do |config|
        config.add_setting :current_date
        config.current_date = Date.new(1993, 10, 3)

        group = RSpec.describe "examples" do
          it "should fail" do
            expect(2).to eq(1)
          end
        end
        group.run
        example = group.examples.first
        subject = described_class.from_example(example)
        expect(subject.last_failed_date).to eq(Date.new(1993, 10, 3))
        expect(subject.last_run_date).to eq(Date.new(1993, 10, 3))
      end
    end
  end
end
