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
    if @state == :pending
      @state = :fulfilled
      @value = value.freeze
      @on_fulfill.call(value) if @on_fulfill
    end
  end

  def reject(reason)
    if @state == :pending
      @state = :rejected
      @reason = reason.freeze
      @on_reject.call(reason) if @on_reject
    end
  end
end
