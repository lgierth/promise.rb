class Promise
  class Group
    attr_reader :promise

    def initialize(promise, input)
      promise.source = self

      @promise = promise
      @total_resolved = 0
      @input = input

      iterate
    end

    def wait
      return unless @input

      @input.each do |obj|
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
      @values.length == @total_resolved
    end

    def iterate
      index = 0
      @values = @input.map do |maybe_promise|
        result =
          if maybe_promise.is_a?(Promise)
            case maybe_promise.state
            when :fulfilled
              @total_resolved += 1
              maybe_promise.value
            when :rejected
              return reject(maybe_promise.reason)
            else
              maybe_promise.send(:add_callback, self, index, nil)
              nil
            end
          else
            @total_resolved += 1
            maybe_promise
          end

        index += 1
        result
      end

      fulfill if resolved?
    end

    def fulfill
      @promise.fulfill(@values)
      @values = @input = nil
    end

    def reject(reason)
      @promise.reject(reason)
      @values = @input = nil
    end
  end

  private_constant :Group
end
