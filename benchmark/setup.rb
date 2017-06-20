# frozen_string_literal: true

require 'promise'
require 'benchmark/ips'
require 'benchmark/memory'
require 'memory_profiler'

module PromiseBenchmark
  module_function

  # Pass a block which will be benchmarked
  def benchmark
    Benchmark.ips { |x| yield(x) }
    Benchmark.memory { |x| yield(x) }
  end

  # Pass a block which will be profiled for memory usage
  def profile_memory
    report = MemoryProfiler.report { yield }
    report.pretty_print
  end
end
