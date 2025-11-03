# frozen_string_literal: true

# -*- mode: ruby -*-

SimpleCov.start do
  # any custom configs like groups and filters can be here at a central place
  add_filter '/spec/'
  add_filter '/tmp/'
  add_group "Models", "lib/fat_table"
  add_group "Core Extension", "lib/ext"
  # After this many seconds between runs, old coverage stats are thrown out,
  # so 3600 => 1 hour
  merge_timeout 3600
  # Make this true to merge rspec and cucumber coverage together
  use_merging false
  command_name 'Rspec'
  nocov_token 'no_cover'
  # Branch coverage
  enable_coverage :branch
end
