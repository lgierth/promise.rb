# encoding: utf-8

class Promise
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
      raise error
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
