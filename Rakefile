# encoding: utf-8

if Gem.ruby_version >= Gem::Version.new('2.1')
  require 'devtools'
  Devtools.init_rake_tasks
  default_task = RUBY_ENGINE == 'ruby' ? :ci : :spec
else
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  default_task = :spec
end

task :default => default_task
