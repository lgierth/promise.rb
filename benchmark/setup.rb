# frozen_string_literal: true

require 'promise'
require 'benchmark/ips'
require 'benchmark/memory'
require 'memory_profiler'

module PromiseBenchmark
  module_function

  # Pass a block which will be benchmarked
  def benchmark(&block)
    Benchmark.ips(&block)
    Benchmark.memory(&block)
  end

  # Pass a block which will be profiled for memory usage
  def profile_memory(&block)
    report = MemoryProfiler.report(&block)
    report.pretty_print
  end
end
