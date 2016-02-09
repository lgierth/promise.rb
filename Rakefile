# encoding: utf-8

if Gem.ruby_version >= Gem::Version.new('2.1')
  require 'devtools'
  Devtools.init_rake_tasks

  tasks = %w[
    metrics:coverage
    metrics:yardstick:verify
    metrics:rubocop
    metrics:flog
    metrics:reek
    spec:integration
  ]
  tasks << 'metrics:mutant' if RUBY_ENGINE == 'ruby'
  tasks = :spec if RUBY_ENGINE == 'rbx'
  task :default => tasks
else
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
end
