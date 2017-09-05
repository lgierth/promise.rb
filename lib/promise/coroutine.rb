class Promise::Coroutine
  include Promise::Observer

  def initialize(promise, fiber)
    @promise = promise
    @fiber = fiber
  end

  attr_reader :promise

  def promise_fulfilled(value, _on_fulfill_arg)
    result = @fiber.resume(:return, value)
  rescue => e
    @promise.reject(e)
  else
    continue(result)
  end

  def promise_rejected(reason, _on_reject_arg)
    result = @fiber.resume(:raise, reason)
  rescue => e
    @fiber = nil
    @promise.reject(e)
  else
    continue(result)
  end

  def continue(result)
    return @promise.fulfill(result) unless @fiber.alive?

    case result.state
    when :fulfilled
      promise.defer { promise_fulfilled(result.value, nil) }
    when :rejected
      promise.defer { promise_rejected(result.reason, nil) }
    else
      result.subscribe(self, nil, nil)
    end
  end
end
