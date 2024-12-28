require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rdoc/task'

require 'rubocop/rake_task'

RuboCop::RakeTask.new

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc', 'lib')
end

RSpec::Core::RakeTask.new(:spec)

task :default => [:spec, :rubocop]
