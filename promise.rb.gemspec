# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'promise/version'

Gem::Specification.new do |spec|
  spec.name          = 'promise.rb'
  spec.version       = Promise::VERSION.dup
  spec.authors       = ['Lars Gierth']
  spec.email         = ['lars.gierth@gmail.com']
  spec.description   = 'Promises/A+ for Ruby'
  spec.summary       = 'Ruby implementation of the Promises/A+ spec'
  spec.homepage      = 'https://github.com/lgierth/promise'
  spec.license       = 'Public Domain'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'benchmark-memory'
  spec.add_development_dependency 'memory_profiler'
  spec.add_development_dependency 'rspec'
end
