# encoding: utf-8

require 'promise/version'

class Promise
  attr_reader :state, :value, :reason

  def initialize
    @state = :pending
    @callbacks = []
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
    callback = [on_fulfill, on_reject, Promise.new]
    add_callback(callback)

    callback[2]
  end

  def fulfill(value)
    if pending?
      fulfill!(value)
      @callbacks.each { |callback| dispatch_fulfill(callback) }
    end
  end

  def reject(reason)
    if pending?
      reject!(reason)
      @callbacks.each { |callback| dispatch_reject(callback) }
    end
  end

  private

  def add_callback(callback)
    @callbacks << callback
    dispatch(callback)
  end

  def fulfill!(value)
    @state = :fulfilled
    @value = value.freeze
  end

  def reject!(reason)
    @state = :rejected
    @reason = reason.freeze
  end

  def dispatch(callback)
    if fulfilled?
      dispatch_fulfill(callback)
    elsif rejected?
      dispatch_reject(callback)
    end
  end

  def dispatch_fulfill(callback)
    run(callback[0], value, callback[2])
  end

  def dispatch_reject(callback)
    run(callback[1], reason, callback[2])
  end

  def run(block, arg, next_promise)
    if block
      result = execute(block, arg, next_promise)
      handle_result(result, next_promise)
    elsif fulfilled?
      handle_result(arg, next_promise)
    elsif rejected?
      next_promise.reject(arg)
    end
  end

  def execute(block, arg, next_promise)
    result = block.call(arg) if block
  rescue => error
    next_promise.reject(error)
    raise error
  end

  def handle_result(result, next_promise)
    if Promise === result
      assume_state(result, next_promise)
    else
      next_promise.fulfill(result)
    end
  end

  def assume_state(returned_promise, next_promise)
    on_fulfill = next_promise.method(:fulfill)
    on_reject = next_promise.method(:reject)

    returned_promise.then(on_fulfill, on_reject)
  end
end
