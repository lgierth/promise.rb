# frozen_string_literal: true

require 'promise'
require_relative 'support/delayed_promise'
require_relative 'support/promise_loader'

require 'awesome_print'
require 'rspec/its'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = true
  config.raise_on_warning = true
end
