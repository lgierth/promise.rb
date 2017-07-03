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
    defined?(@state) ? false : true
  end

  def fulfilled?
    defined?(@state) && @state.equal?(:fulfilled)
  end

  def rejected?
    defined?(@state) && @state.equal?(:rejected)
  end

  def then(on_fulfill = nil, on_reject = nil)
    next_promise = self.class.new

    case defined?(@state) && @state
    when :fulfilled
      if on_fulfill
        defer { next_promise.settle_from_handler(@value, &on_fulfill) }
      elsif block_given?
        defer { next_promise.settle_from_handler(@value) { |v| yield v } }
      else
        defer { next_promise.fulfill(@value) }
      end
    when :rejected
      if on_reject
        defer { next_promise.settle_from_handler(@reason, &on_reject) }
      else
        defer { next_promise.reject(@reason) }
      end
    else
      next_promise.source = self
      on_fulfill ||= Proc.new if block_given?
      add_callback(next_promise, on_fulfill, on_reject)
    end

    next_promise
  end

  def rescue(&block)
    self.then(nil, block)
  end
  alias_method :catch, :rescue

  def sync
    wait if pending?

    case defined?(@state) && @state
    when :fulfilled
      return @value
    when :rejected
      raise @reason
    end

    raise BrokenError
  end

  def fulfill(value = nil)
    return self unless pending?

    @source = nil if defined?(@source)

    if value.is_a?(Promise)
      case value.state
      when :fulfilled
        fulfill(value.value)
      when :rejected
        reject(value.reason)
      else
        @source = value
        value.add_callback(self, nil, nil)
      end
    else
      @value = value
      @state = :fulfilled

      fulfill_promises
    end

    self
  end

  def reject(reason = nil)
    return self unless pending?

    @source = nil if defined?(@source)

    @reason = reason_coercion(reason || Error)
    @state = :rejected

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

  def state
    defined?(@state) ? @state : :pending
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
    @callbacks ||= []
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
    return unless defined?(@callbacks) && @callbacks

    @callbacks.each_slice(3) do |callback, on_fulfill_arg, _on_reject_arg|
      defer { callback.promise_fulfilled(@value, on_fulfill_arg) }
    end

    @callbacks = nil
  end

  def reject_promises
    return unless defined?(@callbacks) && @callbacks

    @callbacks.each_slice(3) do |callback, _on_fulfill_arg, on_reject_arg|
      defer { callback.promise_rejected(@reason, on_reject_arg) }
    end

    @callbacks = nil
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
