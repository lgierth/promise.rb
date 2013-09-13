require 'promise/version'

class Promise
  def then(on_fulfill, on_reject)
    @on_fulfill = on_fulfill
    @on_reject = on_reject
  end

  def reject(reason)
    @on_reject.call(reason)
  end
end
