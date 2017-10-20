class Promise
  class Group
    include Promise::Observer

    attr_accessor :source

    def initialize(promise, input)
      @promise = promise
      @input = input

      @total_count = nil
      @resolved_count = 0

      @values = @input.is_a?(Array) ? Array.new(@input.size) : []
    end

    def wait
      return if resolved?

      @input.each do |obj|
        obj.wait if obj.is_a?(Promise) && obj.pending?
      end
    end

    def promise_fulfilled(value, index)
      @resolved_count += 1
      @values[index] = value
      fulfill if resolved?
    end

    def promise_rejected(reason, _index)
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
            return promise_rejected(maybe_promise.reason, index)
          else
            maybe_promise.subscribe(self, index, index)
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
      @total_count && @total_count == @resolved_count
    end
  end

  private_constant :Group
end
