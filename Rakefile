# encoding: utf-8

if Gem.ruby_version >= Gem::Version.new('2.1')
  task :default => 'ci'

  require 'devtools'
  Devtools.init_rake_tasks
else
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
end
