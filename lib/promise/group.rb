class Promise
  class Group
    attr_reader :promise

    def initialize(promise, values)
      promise.source = self

      @promise = promise
      @values = values.dup
      @total_resolved = 0

      iterate
    end

    def wait
      return if resolved?

      @values.each do |obj|
        obj.wait if obj.is_a?(Promise) && obj.pending?
      end
    end

    def promise_fulfilled(value, index)
      @total_resolved += 1
      @values[index] = value

      fulfill if resolved?
    end

    def promise_rejected(reason, _)
      reject(reason)
    end

    private

    def resolved?
      @values && @values.length == @total_resolved
    end

    def iterate
      @values.each_with_index do |maybe_promise, index|
        if maybe_promise.is_a? Promise
          case maybe_promise.state
          when :fulfilled
            @total_resolved += 1
            @values[index] = maybe_promise.value
          when :rejected
            return reject(maybe_promise.reason)
          else
            target = maybe_promise.send(:target)
            target.send(:add_callback, self, index, nil)
          end
        else
          @total_resolved += 1
        end
      end

      fulfill if resolved?
    end

    def fulfill
      @promise.fulfill(@values)
      @values = nil
    end

    def reject(reason)
      @promise.reject(reason)
      @values = nil
    end
  end

  private_constant :Group
end
