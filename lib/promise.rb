# encoding: utf-8

require 'promise/version'

class Promise
  attr_reader :state, :value, :reason

  def initialize
    @state = :pending
  end

  def then(on_fulfill = nil, on_reject = nil)
    @on_fulfill = on_fulfill
    @on_reject = on_reject
  end

  def fulfill(value)
    if pending?
      fulfill!(value)
      @on_fulfill.call(value) if @on_fulfill
    end
  end

  def reject(reason)
    if pending?
      reject!(reason)
      @on_reject.call(reason) if @on_reject
    end
  end

  def pending?
    @state == :pending
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
end
