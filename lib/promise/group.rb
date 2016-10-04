class Promise
  class Group
    attr_reader :promise

    def initialize(result_promise, inputs)
      @promise = result_promise
      @inputs = inputs
      @remaining = count_promises
      if @remaining.zero?
        promise.fulfill(inputs)
      else
        chain_inputs
      end
    end

    private

    def chain_inputs
      on_fulfill = method(:on_fulfill)
      on_reject = promise.public_method(:reject)
      each_promise do |input_promise|
        input_promise.then(on_fulfill, on_reject)
      end
    end

    def on_fulfill(_result)
      @remaining -= 1
      if @remaining.zero?
        result = @inputs.map { |obj| promise?(obj) ? obj.value : obj }
        promise.fulfill(result)
      end
    end

    def promise?(obj)
      obj.is_a?(Promise)
    end

    def count_promises
      count = 0
      each_promise { count += 1 }
      count
    end

    def each_promise
      @inputs.each do |obj|
        yield obj if promise?(obj)
      end
    end
  end
  private_constant :Group
end
