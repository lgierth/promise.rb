class Promise
  class MappingGroup < Group
    def initialize(result_promise, input, &block)
      super(result_promise, input)

      @block = block
    end

    def promise_fulfilled(value, index)
      return super(value, ~index) if index.negative?

      maybe_promise = begin
        @block.call(value)
      rescue => error
        return promise_rejected(error)
      end

      return super(maybe_promise, index) unless maybe_promise.is_a?(Promise)

      case maybe_promise.state
      when :fulfilled
        super(maybe_promise.value, index)
      when :rejected
        return promise_rejected(maybe_promise.reason)
      else
        maybe_promise.subscribe(self, ~index, nil)
      end
    end
  end

  private_constant :MappingGroup
end
