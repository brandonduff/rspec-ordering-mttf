# RSpec::Ordering::Mttf (Mean Time to Failure) [![Ruby](https://github.com/brandonduff/rspec-ordering-mttf/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/brandonduff/rspec-ordering-mttf/actions/workflows/main.yml)

A custom orderer for RSpec that optimizes for test latency (mean time to failure) over test throughput.

## Why would I want this?

If you do Test-Driven Development, you likely implement some version of this algorithm manually all the time. It's likely you have too many tests to run them all on every change, so you decide which tests to run based on those that are likely to fail and how quickly they run. This orderer uses a basic set of heuristics to automate that work:

1. Never-run tests first, in arbitrary order
1. Group remaining tests by the date at which they most recently failed.
1. Sort groups such that the most recent failure date is first, and never-failing tests are at the end.
1. Within a group, run the fastest tests first.

These heuristics are taken from [JUnitMax](https://junit.org/junit4/javadoc/latest/org/junit/experimental/max/MaxCore.html).

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rspec-ordering-mttf

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rspec-ordering-mttf

## Usage

Call `RSpec::Ordering::Mttf.configure` with the RSpec configuration. This will configure a default global ordering of "mean time to failure." I expect to change these ergonomics soon, but I haven't yet decided how.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

This gem uses Standard for code styling.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brandonduff/rspec-ordering-mttf.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
