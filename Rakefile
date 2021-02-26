# frozen_string_literal: true

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

desc 'Run the benchmark suite in benchmark/run.rb'
task :benchmark do
  require './benchmark/run'
end
