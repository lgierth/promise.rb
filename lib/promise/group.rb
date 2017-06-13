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

    protected

    def promise_fulfilled(value, index)
      @total_resolved += 1
      @values[index] = value

      fulfill if resolved?
    end

    def promise_rejected(reason, _)
      @total_resolved += 1
      reject(reason)
    end

    private

    def resolved?
      @values && @values.length == @total_resolved
    end

    def iterate
      @values.each_with_index do |maybe_promise, index|
        break if resolved?

        if maybe_promise.is_a? Promise
          if maybe_promise.fulfilled?
            promise_fulfilled(maybe_promise.value, index)
          elsif maybe_promise.rejected?
            promise_rejected(maybe_promise.reason, nil)
            break
          else
            target = maybe_promise.send(:target)
            target.send(:add_callback, self, index, nil)
          end
        else
          @total_resolved += 1
          fulfill if resolved?
        end
      end
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
