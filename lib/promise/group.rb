class Promise
  class Group
    attr_accessor :source
    attr_reader :promise

    class Callback
      def initialize(group, index)
        @group = group
        @index = index
      end

      attr_accessor :source

      def fulfill(value)
        @group.send(:promise_fulfilled, value, @index)
      end

      def reject(reason)
        @group.send(:promise_rejected, reason, @index)
      end

      def wait
        @source.wait if defined?(@source)
      end
    end

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

    private

    def resolved?
      @values.length == @total_resolved
    end

    def iterate
      @values.each_with_index do |maybe_promise, index|
        break if resolved?

        if maybe_promise.is_a? Promise
          if maybe_promise.fulfilled?
            promise_fulfilled(maybe_promise.value, index)
          elsif maybe_promise.rejected?
            promise_rejected(maybe_promise.reason)
            break
          else
            maybe_promise.send :add_callback, Callback.new(self, index)
          end
        else
          @total_resolved += 1
          fulfill if resolved?
        end
      end
    end

    def fulfill
      @promise.fulfill(@values)
      remove_instance_variable :@values
    end

    def reject(reason)
      @promise.reject(reason)
      remove_instance_variable :@values
    end

    def promise_fulfilled(value, index)
      @total_resolved += 1
      @values[index] = value

      fulfill if resolved?
    end

    def promise_rejected(reason, _)
      @total_resolved += 1
      reject(reason)
    end
  end
  private_constant :Group
end
