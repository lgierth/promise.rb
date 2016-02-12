# encoding: utf-8

class Promise
  class Callback
    def self.assume_state(source, target)
      on_fulfill = target.method(:fulfill)
      on_reject = target.method(:reject)
      source.then(on_fulfill, on_reject)
    end

    def initialize(promise, on_fulfill, on_reject, next_promise)
      @promise = promise
      @on_fulfill = on_fulfill
      @on_reject = on_reject
      @next_promise = next_promise
    end

    def call
      if @promise.fulfilled?
        call_block(@on_fulfill, @promise.value)
      else
        call_block(@on_reject, @promise.reason)
      end
    end

    def call_block(block, param)
      if block
        begin
          @next_promise.fulfill(block.call(param))
        rescue => ex
          @next_promise.reject(ex)
        end
      else
        self.class.assume_state(@promise, @next_promise)
      end
    end
  end
  private_constant :Callback
end
