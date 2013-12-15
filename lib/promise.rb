# encoding: utf-8

require 'promise/version'

require 'promise/callback'
require 'promise/progress'

class Promise
  include Promise::Progress

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
    on_fulfill ||= block
    next_promise = add_callbacks(on_fulfill, on_reject)

    maybe_dispatch(@on_fulfill.last, @on_reject.last)
    next_promise
  end

  def sync
    wait if pending?
    fail reason if rejected?
    value
  end

  def fulfill(value = nil)
    dispatch(@on_fulfill, value) do
      @state = :fulfilled
      @value = value
    end
  end

  def reject(reason = RuntimeError)
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
      callbacks.each { |callback| dispatch!(callback, arg) }
    end

    # Callback#assume_state uses #dispatch as returned_promise's on_fulfill
    # and on_reject callback. Without an explicit return value, the implicit
    # return value might be the callbacks array, and thus returned_promise
    # would be fulfilled (or rejected) with that array. It would be frozen
    # from then on, letting further calls to #then crash.
    nil
  end

  def maybe_dispatch(fulfill_callback, reject_callback)
    if fulfilled?
      dispatch!(fulfill_callback, value)
    end

    if rejected?
      dispatch!(reject_callback, reason)
    end
  end

  def dispatch!(callback, arg)
    defer { callback.dispatch(arg) }
  end

  def defer
    yield
  end
end
