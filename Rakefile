# frozen_string_literal: true

require "bundler/gem_tasks"
begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # Ignored
end

require "standard/rake"

task default: %i[spec standard]
