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
        @next_promise.send(:settle_from_handler, value, &@on_fulfill)
      else
        @next_promise.fulfill(value)
      end
    end

    def reject(reason)
      if @on_reject
        @next_promise.send(:settle_from_handler, reason, &@on_reject)
      else
        @next_promise.reject(reason)
      end
    end

    def wait
      source.wait
    end
  end
  private_constant :Callback
end
