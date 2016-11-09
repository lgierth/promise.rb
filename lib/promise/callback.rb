# encoding: utf-8

class Promise
  class Callback
    attr_accessor :source

    def initialize(on_fulfill, on_reject, next_promise)
      @on_fulfill = on_fulfill
      @on_reject = on_reject
      @next_promise = next_promise
      @next_promise.source = self
    end

    def fulfill(value)
      if @on_fulfill
        call_block(@on_fulfill, value)
      else
        @next_promise.fulfill(value)
      end
    end

    def reject(reason)
      if @on_reject
        call_block(@on_reject, reason)
      else
        @next_promise.reject(reason)
      end
    end

    def wait
      source.wait
    end

    private

    def call_block(block, param)
      @next_promise.fulfill(block.call(param))
    rescue => ex
      @next_promise.reject(ex)
    end
  end
  private_constant :Callback
end
