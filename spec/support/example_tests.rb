shared_context "Example Tests" do
  let(:current_date) { Date.new(1993, 10, 3) }

  around do |example|
    RSpec::Core::Sandbox.sandboxed do |config|
      config.add_setting :current_date
      config.current_date = current_date
      example.run
    end
  end

  def passing_example
    sample_examples.last
  end

  def failing_example
    sample_examples.first
  end

  def sample_examples
    sample_group.examples
  end

  def sample_group
    @sample_group ||= begin
      group = RSpec.describe "examples" do
        it "should fail" do
          expect(2).to eq(1)
        end

        it "should pass" do
          expect(2).to eq(2)
        end
      end
      group.run
      group
    end
  end
end
