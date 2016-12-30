require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc 'Default: run specs and features'
task default: [:all]

desc 'Run specs and features'
RSpec::Core::RakeTask.new(:all) do |t|
  t.pattern = 'spec/{**/*_spec.rb,features/**/*.feature}'
end

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end
