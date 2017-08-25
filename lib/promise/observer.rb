class Promise
  # The `Promise::Observer` module allows an object to be
  # notified of `Promise` state changes.
  #
  # See `Promise#subscribe`.
  module Observer
    def promise_fulfilled(_value, _on_fulfill_arg); end

    def promise_rejected(_reason, _on_reject_arg); end
  end
end
