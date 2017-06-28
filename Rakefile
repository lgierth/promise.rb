# encoding: utf-8

if Gem.ruby_version >= Gem::Version.new('2.2')
  require 'devtools'
  Devtools.init_rake_tasks

  tasks = %w[
    metrics:yardstick:verify
    metrics:rubocop
    metrics:flog
    metrics:reek
    spec:integration
  ]
  tasks << 'metrics:coverage' unless RUBY_ENGINE == 'rbx'
  tasks << 'metrics:mutant' if RUBY_ENGINE == 'ruby'
  task :default => tasks
else
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
end


desc "Run the benchmark suite in benchmark/run.rb"
task :benchmark do
  require "./benchmark/run.rb"
end
