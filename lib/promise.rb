# encoding: utf-8

require 'promise/version'

class Promise
  attr_reader :state, :value, :reason

  def initialize
    @state = :pending
    @on_fulfill = []
    @on_reject = []
    @on_progress = []
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

  def then(on_fulfill = nil, on_reject = nil)
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

  def on_progress(block)
    @on_progress << block
  end

  def progress(status)
    if pending?
      @on_progress.each { |block| block.call(status) }
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

  class Callback
    def initialize(block, next_promise)
      @block = block
      @next_promise = next_promise
    end

    private

    def execute(value)
      @block.call(value)
    rescue => error
      @next_promise.reject(error)
    end

    def handle_result(result)
      if Promise === result
        assume_state(result)
      else
        @next_promise.fulfill(result)
      end
    end

    def assume_state(returned_promise)
      on_fulfill = @next_promise.method(:fulfill)
      on_reject = @next_promise.method(:reject)

      returned_promise.then(on_fulfill, on_reject)
    end
  end

  class FulfillCallback < Callback
    def dispatch(value)
      if @block
        result = execute(value)
        handle_result(result)
      else
        handle_result(value)
      end
    end
  end

  class RejectCallback < Callback
    def dispatch(reason)
      if @block
        result = execute(reason)
        handle_result(result)
      else
        @next_promise.reject(reason)
      end
    end
  end
end
