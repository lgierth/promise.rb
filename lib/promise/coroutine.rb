require 'fiber'

class Promise
  def self.coroutine
    promise = new
    Promise::Coroutine.new(promise) { yield }.continue
    promise
  end

  def self.await(promise)
    case promise.state
    when :fulfilled
      return promise.value
    when :rejected
      raise promise.reason
    end

    action, value = Fiber.yield(promise)

    case action
    when :return
      return value
    when :raise
      raise value
    end
  end

  class Coroutine
    include Promise::Observer

    def initialize(promise)
      @promise = promise
      @promise.source = self

      @fiber = Fiber.new do
        begin
          result = yield
        rescue => e
          promise.reject(e)
        else
          promise.fulfill(result)
        end
      end
    end

    def wait
      while @source
        source = @source
        @source = nil
        source.wait
      end
    end

    def continue(value = nil , action = nil)
      loop do
        result = @fiber.resume(action, value)
        break unless @fiber.alive?

        case result.state
        when :fulfilled
          action = :return
          value = result.value
        when :rejected
          action = :raise
          value = result.reason
        else
          @source = result
          result.subscribe(self, :return, :raise)

          break
        end
      end
    end

    alias promise_fulfilled continue
    alias promise_rejected continue
  end
end
