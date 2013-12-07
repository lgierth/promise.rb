# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'promise/version'

Gem::Specification.new do |spec|
  spec.name          = 'promise.rb'
  spec.version       = Promise::VERSION
  spec.authors       = ['Lars Gierth']
  spec.email         = ['lars.gierth@gmail.com']
  spec.description   = %q{Promises/A+ for Ruby}
  spec.summary       = %q{Ruby implementation of the Promises/A+ spec}
  spec.homepage      = 'https://github.com/lgierth/promise'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rspec'
end
