# encoding: utf-8

require 'promise/version'

require 'promise/callback'
require 'promise/progress'
require 'promise/group'

class Promise
  Error = Class.new(RuntimeError)

  include Promise::Progress

  attr_reader :state, :value, :reason, :backtrace

  def self.resolve(obj)
    return obj if obj.instance_of?(self)
    new.tap { |promise| promise.fulfill(obj) }
  end

  def self.all(enumerable)
    Group.new(enumerable).promise
  end

  def initialize
    @state = :pending
    @callbacks = []
  end

  def pending?
    @state.equal?(:pending)
  end

  def fulfilled?
    @state.equal?(:fulfilled)
  end

  def rejected?
    @state.equal?(:rejected)
  end

  def then(on_fulfill = nil, on_reject = nil, &block)
    on_fulfill ||= block
    next_promise = Promise.new

    add_callback { Callback.new(self, on_fulfill, on_reject, next_promise) }
    next_promise
  end

  def add_callback(&generator)
    if pending?
      @callbacks << generator
    else
      dispatch!(generator.call)
    end
  end

  def sync
    wait if pending?
    raise reason if rejected?
    value
  end

  def fulfill(value = nil, backtrace = nil)
    dispatch(backtrace) do
      @state = :fulfilled
      @value = value
    end
  end

  def reject(reason = nil, backtrace = nil)
    dispatch(backtrace) do
      @state = :rejected
      @reason = reason || Error
    end
  end

  def dispatch(backtrace)
    if pending?
      yield
      @backtrace = backtrace || caller
      @callbacks.each { |generator| dispatch!(generator.call) }
      nil
    end
  end

  def dispatch!(callback)
    defer { callback.dispatch }
  end

  def defer
    yield
  end
end
