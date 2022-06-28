require 'date'
require 'rspec/core/sandbox'
require 'rspec/ordering/mttf'

describe RSpec::Ordering::Mttf do
  it 'has a version' do
    expect(described_class::VERSION).to eq('0.1.0')
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
    it 'runs examples that have never been run first' do
      run_order = run_with_ordering_log do |ordering_log|
        RSpec.describe 'unordered group' do
          it 'runs this one second', last_run_date: Date.today, last_failed_date: Date.today do
            ordering_log << 2
          end

          it 'runs this one last', last_run_date: Date.today do
            ordering_log << 3
          end

          it 'runs this one first' do
            ordering_log << 1
          end
        end
      end

      expect(run_order).to eq([1, 2, 3])
    end

    it 'runs examples that have failed more recently first' do
      run_order = run_with_ordering_log do |ordering_log|
        RSpec.describe 'unordered group' do
          it 'runs this one second', last_run_date: Date.today, last_failed_date: Date.today - 2 do
            ordering_log << 2
          end

          it 'runs this one last', last_run_date: Date.today, last_failed_date: Date.today - 3 do
            ordering_log << 3
          end

          it 'runs this one first', last_run_date: Date.today, last_failed_date: Date.today do
            ordering_log << 1
          end
        end
      end

      expect(run_order).to eq([1, 2, 3])
    end
  end
end