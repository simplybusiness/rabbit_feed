require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc 'Default: run specs and features'
task :default => [:specs]

desc 'Run specs'
RSpec::Core::RakeTask.new(:specs) do |t|
  t.pattern = './spec/{**/*_spec.rb,features/**/*.feature}'
end

def gemspec
  @gemspec ||= eval(File.read('rabbit_feed.gemspec'))
end

desc 'Validate gemspec'
task :validate_gemspec do
  gemspec.validate
end

desc 'Print version'
task :version do
  puts gemspec.version
end

