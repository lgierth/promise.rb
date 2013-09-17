# encoding: utf-8

require 'promise/version'

class Promise
  attr_reader :state, :value, :reason

  def initialize
    @state = :pending
    @callbacks = []
  end

  def then(on_fulfill = nil, on_reject = nil)
    promise2 = Promise.new
    on_fulfill = link_to_next(on_fulfill, promise2) if on_fulfill
    on_reject = link_to_next(on_reject, promise2) if on_reject

    if fulfilled?
      on_fulfill.call(value)
    elsif rejected?
      on_reject.call(reason)
    else
      @callbacks << [on_fulfill, on_reject]
    end

    promise2
  end

  def fulfill(value)
    if pending?
      fulfill!(value)
      @callbacks.each { |(cb, _)| cb.call(value) if cb }
    end
  end

  def reject(reason)
    if pending?
      reject!(reason)
      @callbacks.each { |(_, cb)| cb.call(reason) if cb }
    end
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

  private

  def fulfill!(value)
    @state = :fulfilled
    @value = value.freeze
  end

  def reject!(reason)
    @state = :rejected
    @reason = reason.freeze
  end

  def link_to_next(callback, promise)
    proc { |arg| call_with_next(callback, arg, promise) }
  end

  def call_with_next(callback, arg, promise)
    begin
      result = callback.call(arg)
    rescue => error
    end

    if error
      promise.reject(error)
    else
      promise.fulfill(result)
    end
  end
end
