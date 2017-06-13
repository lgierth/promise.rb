# encoding: utf-8

require 'promise/version'

require 'promise/progress'
require 'promise/group'

class Promise
  Error = Class.new(RuntimeError)
  BrokenError = Class.new(Error)

  include Promise::Progress

  attr_accessor :source
  attr_reader :value, :reason

  def self.resolve(obj = nil)
    return obj if obj.is_a?(self)
    new.fulfill(obj)
  end

  def self.all(enumerable)
    return new.fulfill([]) if enumerable.empty?

    Group.new(new, enumerable).promise
  end

  def self.map_value(obj)
    if obj.is_a?(Promise)
      obj.then { |value| yield value }
    else
      yield obj
    end
  end

  def self.sync(obj)
    obj.is_a?(Promise) ? obj.sync : obj
  end

  def pending?
    !defined?(@value) && !defined?(@reason)
  end

  def fulfilled?
    !!defined?(@value)
  end

  def rejected?
    !!defined?(@reason)
  end

  def then(on_fulfill = nil, on_reject = nil)
    next_promise = self.class.new

    if fulfilled?
      if on_fulfill
        next_promise.settle_from_handler(@value, &on_fulfill)
      elsif block_given?
        next_promise.settle_from_handler(@value) { |v| yield v }
      else
        next_promise.fulfill(@value)
      end
    elsif rejected?
      if on_reject
        next_promise.settle_from_handler(@reason, &on_reject)
      else
        next_promise.reject(@reason)
      end
    else
      next_promise.source = self
      add_callback(next_promise, on_fulfill || (block_given? ? Proc.new : nil), on_reject)
    end

    next_promise
  end

  def rescue(&block)
    self.then(nil, block)
  end
  alias_method :catch, :rescue

  def sync
    return value if fulfilled?
    raise reason if rejected?

    wait

    return value if fulfilled?
    raise reason if rejected?

    raise BrokenError
  end

  def fulfill(value = nil)
    return self unless pending?

    if value.is_a?(Promise)
      if value.fulfilled?
        fulfill(value.value)
      elsif value.rejected?
        reject(value.reason)
      else
        self.source = value
        value.add_callback(self, nil, nil)
      end
    else
      remove_instance_variable :@source if defined?(@source)
      @value = value
      fulfill_promises
    end

    self
  end

  def reject(reason = nil)
    return self unless pending?

    remove_instance_variable :@source if defined?(@source)
    @reason = reason_coercion(reason || Error)
    reject_promises

    self
  end

  # Override to support sync on a promise without a source or to wait
  # for deferred callbacks on the source
  def wait
    while source
      saved_source = source
      saved_source.wait
      break if saved_source.equal?(source)
    end
  end

  protected

  # Override to defer calling the callback for Promises/A+ spec compliance
  def defer
    yield
  end

  def settle_from_handler(value)
    fulfill(yield(value))
  rescue => ex
    reject(ex)
  end

  def add_callback(callback, on_fulfill_arg, on_reject_arg)
    @callbacks = [] unless defined?(@callbacks)
    @callbacks.push(callback, on_fulfill_arg, on_reject_arg)
  end

  def promise_fulfilled(value, on_fulfill)
    if on_fulfill
      settle_from_handler(value, &on_fulfill)
    else
      fulfill(value)
    end
  end

  def promise_rejected(reason, on_reject)
    if on_reject
      settle_from_handler(reason, &on_reject)
    else
      reject(reason)
    end
  end

  private

  def fulfill_promises
    return unless defined?(@callbacks)

    @callbacks.each_slice(3) do |callback, on_fulfill_arg, _|
      defer { callback.send(:promise_fulfilled, @value, on_fulfill_arg) }
    end

    remove_instance_variable :@callbacks
  end

  def reject_promises
    return unless defined?(@callbacks)

    @callbacks.each_slice(3) do |callback, _, on_reject_arg|
      defer { callback.send(:promise_rejected, @reason, on_reject_arg) }
    end

    remove_instance_variable :@callbacks
  end

  def reason_coercion(reason)
    case reason
    when Exception
      reason.set_backtrace(caller) unless reason.backtrace
    when Class
      reason = reason_coercion(reason.new) if reason <= Exception
    end
    reason
  end
end
