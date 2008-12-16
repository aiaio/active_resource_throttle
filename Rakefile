require 'rubygems'
require 'rake'
require 'rake/testtask'
require './lib/active_resource_throttle.rb'

desc 'Default: run unit tests.'
task :default => :test

test_files_pattern = 'test/**/*_test.rb'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = test_files_pattern
  t.verbose = false
end
