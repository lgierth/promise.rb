class Promise
  class Group
    include Promise::Observer

    attr_accessor :source

    def initialize(promise, input)
      @promise = promise
      @promise.source = self

      @input = input
      @values = []

      @resolved_count = 0
    end

    def wait
      @input.each do |obj|
        obj.wait if obj.is_a?(Promise) && obj.pending?
      end
    end

    def promise_fulfilled(value, index)
      @resolved_count += 1
      @values[index] = value
      fulfill if resolved?
    end

    def promise_rejected(reason, _ = nil)
      @promise.reject(reason)
    end

    def perform
      index = 0

      @input.each do |maybe_promise|
        if maybe_promise.is_a?(Promise)
          case maybe_promise.state
          when :fulfilled
            promise_fulfilled(maybe_promise.value, index)
          when :rejected
            return promise_rejected(maybe_promise.reason)
          else
            maybe_promise.subscribe(self, index, nil)
          end
        else
          promise_fulfilled(maybe_promise, index)
        end

        index += 1
      end

      @total_count = index

      fulfill if resolved?

      @promise
    end

    private

    def fulfill
      @promise.fulfill(@values)
    end

    def resolved?
      @total_count == @resolved_count
    end
  end

  private_constant :Group
end
