class Promise
  class FilterGroup < MappingGroup
    def initialize(result_promise, input, &block)
      super

      @preserved_values = @values.dup
    end

    protected

    def promise_fulfilled(value, index)
      @preserved_values[index] = value unless index.negative?

      super
    end

    def fulfill
      result = []

      @preserved_values.each_with_index do |value, index|
        result.push(value) if @values[index]
      end

      @promise.fulfill(result)
    end
  end

  private_constant :MappingGroup
end
