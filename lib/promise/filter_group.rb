class Promise
  class FilterGroup < MappingGroup
    def initialize(result_promise, input, &block)
      super(result_promise, input, &block)

      @preserved_values = []
    end

    def promise_fulfilled(value, index)
      @preserved_values[index] = value unless index.negative?

      super
    end

    protected

    def fulfill
      result = []

      @preserved_values.zip(@values) do |value, check|
        result.push(value) if check
      end

      @promise.fulfill(result)
    end
  end

  private_constant :MappingGroup
end
