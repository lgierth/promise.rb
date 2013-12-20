# encoding: utf-8

class Promise
  class Callback
    def initialize(on_fulfill, on_reject, next_promise)
      @on_fulfill, @on_reject = on_fulfill, on_reject
      @next_promise = next_promise
    end

    def block_for(promise)
      promise.fulfilled? ? @on_fulfill : @on_reject
    end

    def param_for(promise)
      promise.fulfilled? ? promise.value : promise.reason
    end

    def dispatch(promise)
      if (block = block_for(promise))
        handle_result(promise) { execute(promise, block) }
      else
        assume_state(promise, @next_promise)
      end
    end

    def execute(promise, block)
      block.call(param_for(promise))
    rescue => ex
      @next_promise.reject(ex, promise.backtrace)
      raise
    end

    def handle_result(promise)
      if Promise === (result = yield)
        assume_state(result, @next_promise)
      else
        @next_promise.fulfill(result, promise.backtrace)
      end
    end

    def assume_state(source, target)
      on_fulfill = proc { target.fulfill(source.value, source.backtrace) }
      on_reject  = proc { target.reject(source.reason, source.backtrace) }

      source.then(on_fulfill, on_reject)
    end
  end
end
