# encoding: utf-8

class Promise
  class Callback
    def initialize(promise, on_fulfill, on_reject, next_promise)
      @promise = promise
      @on_fulfill, @on_reject = on_fulfill, on_reject
      @next_promise = next_promise
    end

    def block
      @promise.fulfilled? ? @on_fulfill : @on_reject
    end

    def param
      @promise.fulfilled? ? @promise.value : @promise.reason
    end

    def dispatch
      if block
        handle_result { execute }
      else
        assume_state(@promise, @next_promise)
      end
    end

    def execute
      block.call(param)
    rescue => ex
      @next_promise.reject(ex, @promise.backtrace)
      raise
    end

    def handle_result
      if Promise === (result = yield)
        assume_state(result, @next_promise)
      else
        @next_promise.fulfill(result, @promise.backtrace)
      end
    end

    def assume_state(source, target)
      on_fulfill = proc { target.fulfill(source.value, source.backtrace) }
      on_reject  = proc { target.reject(source.reason, source.backtrace) }

      source.then(on_fulfill, on_reject)
    end
  end
end
