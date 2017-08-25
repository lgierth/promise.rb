class Promise
  class Group
    include Promise::Observer

    attr_accessor :source
    attr_reader :promise

    def initialize(result_promise, inputs)
      @promise = result_promise
      @inputs = inputs
      @remaining = count_promises

      promise.source = self
      chain_inputs
    end

    def wait
      each_promise do |input_promise|
        input_promise.wait if input_promise.pending?
      end
    end

    def promise_fulfilled(_value, _arg)
      @remaining -= 1
      if @remaining.zero?
        result = @inputs.map { |obj| promise?(obj) ? obj.value : obj }
        promise.fulfill(result)
      end
    end

    def promise_rejected(reason, _arg)
      promise.reject(reason)
    end

    private

    def chain_inputs
      each_promise do |input_promise|
        if input_promise.pending?
          input_promise.subscribe(self, nil, nil)
        elsif input_promise.rejected?
          return promise_rejected(input_promise.reason, nil)
        end
      end

      promise.fulfill(@inputs.dup) if @remaining.zero?
    end

    def promise?(obj)
      obj.is_a?(Promise)
    end

    def count_promises
      count = 0
      each_promise { |input_promise| count += 1 if input_promise.pending? }
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
