class DelayedPromise < Promise
  BrokenPromise = Class.new(StandardError)

  class << self
    def deferred
      @deferred ||= []
    end

    def call_deferred
      deferred.shift.call until deferred.empty?
    end
  end

  def wait
    DelayedPromise.call_deferred
    raise BrokenPromise if pending?
  end

  def defer(&block)
    DelayedPromise.deferred << block
  end
end
