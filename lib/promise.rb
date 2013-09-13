require 'promise/version'

class Promise
  def then(on_fulfill = nil, on_reject = nil)
    @on_fulfill = on_fulfill
    @on_reject = on_reject
  end

  def fulfill(value)
    @on_fulfill.call(value) if @on_fulfill
  end

  def reject(reason)
    @on_reject.call(reason) if @on_reject
  end
end
