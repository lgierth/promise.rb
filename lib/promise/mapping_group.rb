class Promise
  class MappingGroup < Group
    def initialize(result_promise, input, &block)
      super(result_promise, input)

      @block = block
    end

    def promise_fulfilled(value, index)
      if index.negative?
        super(value, ~index)
      else
        maybe_promise = begin
          @block.call(value)
        rescue => error
          return promise_rejected(error, index)
        end

        if maybe_promise.is_a?(Promise)
          case maybe_promise.state
          when :fulfilled
            super(maybe_promise.value, index)
          when :rejected
            return promise_rejected(maybe_promise.reason, index)
          else
            maybe_promise.subscribe(self, ~index, ~index)
          end
        else
          super(maybe_promise, index)
        end
      end
    end
  end

  private_constant :MappingGroup
end
