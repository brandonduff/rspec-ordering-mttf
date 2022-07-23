guard :rspec, cmd: "rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)
  notification :emacs

  rspec = dsl.rspec
  ruby = dsl.ruby
  watch(ruby.lib_files) { rspec.spec_dir }
end
