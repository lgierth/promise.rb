# encoding: utf-8

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    command_name 'spec:unit'

    add_filter 'config'
    add_filter 'spec'
  end
end

require 'promise'
require_relative 'support/delayed_promise'
require_relative 'support/promise_loader'

require 'awesome_print'
require 'devtools/spec_helper' if Gem.ruby_version >= Gem::Version.new('2.1')
require 'rspec/its'
