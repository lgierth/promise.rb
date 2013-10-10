# encoding: utf-8

require 'promise/version'

require 'promise/callback'
require 'promise/progress'

class Promise
  attr_reader :value, :reason

  def initialize
    @state = :pending
    @on_fulfill = []
    @on_reject = []
  end

  def pending?
    @state == :pending
  end

  def fulfilled?
    @state == :fulfilled
  end

  def rejected?
    @state == :rejected
  end

  def then(on_fulfill = nil, on_reject = nil, &block)
    on_fulfill = block if block
    next_promise = add_callbacks(on_fulfill, on_reject)

    maybe_dispatch(@on_fulfill.last, @on_reject.last)
    next_promise
  end

  def fulfill(value)
    dispatch(@on_fulfill, value) do
      @state = :fulfilled
      @value = value
    end
  end

  def reject(reason)
    dispatch(@on_reject, reason) do
      @state = :rejected
      @reason = reason
    end
  end

  private

  def add_callbacks(on_fulfill, on_reject)
    next_promise = self.class.new
    @on_fulfill << FulfillCallback.new(on_fulfill, next_promise)
    @on_reject << RejectCallback.new(on_reject, next_promise)
    next_promise
  end

  def dispatch(callbacks, arg)
    if pending?
      yield
      arg.freeze
      callbacks.each { |callback| defer(callback, arg) }
    end
    nil
  end

  def maybe_dispatch(fulfill_callback, reject_callback)
    if fulfilled?
      defer(fulfill_callback, value)
    end

    if rejected?
      defer(reject_callback, reason)
    end
  end

  def defer(callback, arg)
    callback.dispatch(arg)
  end
end
