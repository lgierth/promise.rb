class Promise
  class Group
    include Promise::Observer

    attr_accessor :source
    attr_reader :promise

    def initialize(result_promise, inputs)
      @promise = result_promise
      @inputs = inputs
      @remaining = count_promises

      if @remaining.zero?
        promise.fulfill(inputs)
      else
        promise.source = self
        chain_inputs
      end
    end

    def wait
      each_promise do |input_promise|
        input_promise.wait if input_promise.pending?
      end
    end

    def promise_fulfilled(_value = nil, _arg = nil)
      @remaining -= 1
      if @remaining.zero?
        result = @inputs.map { |obj| promise?(obj) ? obj.value : obj }
        promise.fulfill(result)
      end
    end

    def promise_rejected(reason, _arg = nil)
      promise.reject(reason)
    end

    private

    def chain_inputs
      each_promise do |input_promise|
        case input_promise.state
        when :fulfilled
          promise_fulfilled
        when :rejected
          promise_rejected(input_promise.reason)
        else
          input_promise.subscribe(self, nil, nil)
        end
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
