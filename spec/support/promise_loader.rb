class PromiseLoader
  def self.lazy_load(promise, &block)
    promise.source = new(&block)
  end

  def initialize(&block)
    @block = block
  end

  def wait
    @block.call
  end
end
