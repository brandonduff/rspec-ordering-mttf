# frozen_string_literal: true

require_relative "mttf/version"

module RSpec
  module Ordering
    module Mttf
      class Orderer
        def order(items)
          items.sort do |a, b|
            if a.metadata[:last_run_date].nil?
              -1
            elsif b.metadata[:last_run_date].nil?
              1
            elsif a.metadata[:last_failed_date].nil?
              1
            elsif b.metadata[:last_failed_date].nil?
              -1
            else
              b.metadata[:last_failed_date] <=> a.metadata[:last_failed_date]
            end
          end
        end
      end
    end
  end
end
