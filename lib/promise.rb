# encoding: utf-8

require 'promise/version'

require 'promise/callback'
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
    !defined?(@value) && !defined?(@reason)
  end

  def fulfilled?
    !!defined?(@value)
  end

  def rejected?
    !!defined?(@reason)
  end

  def then(on_fulfill = nil, on_reject = nil)
    on_fulfill = Proc.new if on_fulfill.nil? && block_given?
    next_promise = self.class.new

    callback = Callback.new(on_fulfill, on_reject, next_promise)

    if fulfilled?
      callback.fulfill(value)
    elsif rejected?
      callback.reject(reason)
    else
      add_callback(callback)
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
        value.add_callback(self)
      end
    else
      @source = nil
      @value = value
      fulfill_promises
    end

    self
  end

  def reject(reason = nil)
    return self unless pending?

    @source = nil
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

  def add_callback(callback)
    @callbacks = [] unless defined?(@callbacks)
    @callbacks << callback
    callback.source = self
  end

  private

  def fulfill_promises
    return unless defined?(@callbacks)

    @callbacks.each { |callback| defer { callback.fulfill(@value) } }
  end

  def reject_promises
    return unless defined?(@callbacks)

    @callbacks.each { |callback| defer { callback.reject(@reason) } }
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
