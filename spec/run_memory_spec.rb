RSpec.describe RSpec::Ordering::Mttf::RunMemory do
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

    expect(subject.read[example_group.examples.first].status).to eq(:passed)
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

    expect(subject.read[group].status).to eq(:failed)
    expect(subject.read[group.descendants.last].status).to eq(:passed)
  end

  it "uses the most relevant status from the child example group for the parent" do
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
    expect(subject.read[group].status).to eq(:failed)
  end

  it "puts the top-level status as passing if all sub groups pass" do
    group = sandboxed do |runner|
      group = RSpec.describe "some examples" do
        describe "a nested group" do
          it "passes" do
            expect(2).to eq(2)
          end
        end

        describe "another nested group" do
          it "passes" do
            expect(2).to eq(2)
          end
        end
      end
      runner.call(group)
      group
    end
    expect(subject.read[group].status).to eq(:passed)
  end

  it "propagates up deeply nested groups" do
    group = sandboxed do |runner|
      group = RSpec.describe "some examples" do
        describe "in a group" do
          describe "inside of another a group" do
            it "fails" do
              expect(2).to eq(e)
            end
          end
        end
      end
      runner.call(group)
      group
    end
    expect(subject.read[group].status).to eq(:failed)
  end

  it "loads metadata from previous runs" do
    last_run_date = last_failed_date = nil
    ordering_log = []
    run_examples = -> do
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
      end
    end

    2.times { run_examples.call }

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
