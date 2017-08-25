# encoding: utf-8

require 'spec_helper'

describe Promise do
  subject { Promise.new }

  let(:value) { double('value') }
  let(:other_value) { double('other_value') }

  let(:backtrace) { caller }
  let(:reason) do
    StandardError.new('reason').tap { |err| err.set_backtrace(backtrace) }
  end
  let(:other_reason) do
    StandardError.new('other_reason').tap { |err| err.set_backtrace(caller) }
  end

  describe '3.1.1 pending' do
    it 'transitions to fulfilled' do
      subject.fulfill(value)
      expect(subject).to be_fulfilled
    end

    it 'transitions to rejected' do
      subject.reject(reason)
      expect(subject).to be_rejected
    end
  end

  describe '3.1.2 fulfilled' do
    it 'does not transition to other states' do
      subject.fulfill(value)
      subject.reject(reason)
      expect(subject).to be_fulfilled
    end

    it 'has a value' do
      subject.fulfill(value)
      expect(subject.value).to eq(value)

      subject.fulfill(other_value)
      expect(subject.value).to eq(value)
    end
  end

  describe '3.1.3 rejected' do
    it 'does not transition to other states' do
      subject.reject(reason)
      subject.fulfill(value)
      expect(subject).to be_rejected
    end

    it 'has a reason' do
      subject.reject(reason)
      expect(subject.reason).to eq(reason)

      subject.reject(other_reason)
      expect(subject.reason).to eq(reason)
    end
  end

  describe '3.2.1 on_fulfill' do
    it 'is optional' do
      subject.then
      subject.fulfill(value)
    end
  end

  describe '3.2.1 on_reject' do
    it 'is optional' do
      subject.then(proc { |_| })
      subject.reject(reason)
    end
  end

  describe '3.2.2 on_fulfill' do
    it 'is called after promise is fulfilled' do
      fulfilled = nil
      subject.then(proc { |_| fulfilled = subject.fulfilled? })

      subject.fulfill(value)
      expect(fulfilled).to eq(true)
    end

    it 'is called with fulfillment value' do
      result = nil
      subject.then(proc { |val| result = val })

      subject.fulfill(value)
      expect(result).to eq(value)
    end

    it 'is called not more than once' do
      called = 0
      subject.then(proc { |_| called += 1 })

      subject.fulfill(value)
      subject.fulfill(value)
      expect(called).to eq(1)
    end

    it 'is not called if on_reject has been called' do
      called = false
      subject.then(proc { |_| called = true })

      subject.reject(reason)
      expect(called).to eq(false)
    end

    it 'can be passed as a block' do
      result = nil
      subject.then { |val| result = val }

      subject.fulfill(value)
      expect(result).to eq(value)
    end

    it 'takes precedence over block' do
      result = nil
      subject.then(proc { |_| result = :arg }) { |_| result = :block }

      subject.fulfill(value)
      expect(result).to be(:arg)
    end
  end

  describe '3.2.3 on_reject' do
    it 'is called after promise is rejected' do
      rejected = nil
      subject.then(nil, proc { |_| rejected = subject.rejected? })

      subject.reject(reason)
      expect(rejected).to eq(true)
    end

    it 'is called with rejection reason' do
      result = nil
      subject.then(nil, proc { |reas| result = reas })

      subject.reject(reason)
      expect(result).to eq(reason)
    end

    it 'is called not more than once' do
      called = 0
      subject.then(nil, proc { |_| called += 1 })

      subject.reject(reason)
      subject.reject(reason)
      expect(called).to eq(1)
    end

    it 'is not called if on_fulfill has been called' do
      called = false
      subject.then(nil, proc { |_| called = true })

      subject.fulfill(value)
      expect(called).to eq(false)
    end
  end

  describe '3.2.4' do
    it 'returns before on_fulfill is called when fulfilling a promise' do
      called = false
      p1 = DelayedPromise.new
      p2 = p1.then { called = true }

      p1.fulfill(42)

      expect(called).to eq(false)
      DelayedPromise.call_deferred
      expect(called).to eq(true)
      expect(p2).to be_fulfilled
    end

    it 'returns before on_reject is called when rejecting a promise' do
      called = false
      p1 = DelayedPromise.new
      p2 = p1.then(nil, lambda do |err|
        called = true
        raise err
      end)

      p1.reject(42)

      expect(called).to eq(false)
      DelayedPromise.call_deferred
      expect(called).to eq(true)
      expect(p2).to be_rejected
    end

    it 'returns before on_fulfill is called for a fulfilled promise' do
      called = false
      p1 = DelayedPromise.new
      p1.fulfill(42)

      p2 = p1.then { called = true }

      expect(p2).to be_pending
      expect(called).to eq(false)

      DelayedPromise.call_deferred

      expect(called).to eq(true)
      expect(p2).to be_fulfilled
    end

    it 'returns before on_reject is called for a rejected promise' do
      called = false
      p1 = DelayedPromise.new
      p1.reject(42)

      p2 = p1.then(nil, lambda { |err|
        called = true
        raise err
      })

      expect(p2).to be_pending
      expect(called).to eq(false)

      DelayedPromise.call_deferred

      expect(called).to eq(true)
      expect(p2).to be_rejected
    end
  end

  describe '3.2.5' do
    it 'calls multiple on_fulfill callbacks in order of definition' do
      order = []
      on_fulfill = proc do |i, val|
        order << i
        expect(val).to eq(value)
      end

      subject.then(on_fulfill.curry[1])
      subject.then(on_fulfill.curry[2])

      subject.fulfill(value)
      subject.then(on_fulfill.curry[3])

      expect(order).to eq([1, 2, 3])
    end

    it 'calls all on_fulfill callbacks even if one raises an exception' do
      order = []
      on_fulfill = proc do |i, val|
        order << i
        expect(val).to eq(value)
      end

      subject.then(on_fulfill.curry[1])
      subject.then do |_|
        order << 2
        raise 'middle then error'
      end
      subject.then(on_fulfill.curry[3])

      subject.fulfill(value)

      expect(order).to eq([1, 2, 3])
    end

    it 'calls multiple on_reject callbacks in order of definition' do
      order = []
      on_reject = proc do |i, reas|
        order << i
        expect(reas).to eq(reason)
      end

      subject.then(nil, on_reject.curry[1])
      subject.then(nil, on_reject.curry[2])

      subject.reject(reason)
      subject.then(nil, on_reject.curry[3])

      expect(order).to eq([1, 2, 3])
    end
  end

  describe '3.2.6' do
    let(:error) { StandardError.new }
    let(:returned_promise) { Promise.new }

    it 'returns promise2' do
      expect(subject.then).to be_a(Promise)
      expect(subject.then).not_to eq(subject)
    end

    it 'fulfills promise2 with value returned by on_fulfill' do
      promise2 = subject.then(proc { |_| other_value })
      subject.fulfill(value)

      expect(promise2).to be_fulfilled
      expect(promise2.value).to eq(other_value)
    end

    it 'fulfills promise2 with value returned by on_reject' do
      promise2 = subject.then(nil, proc { |_| other_value })
      subject.reject(reason)

      expect(promise2).to be_fulfilled
      expect(promise2.value).to eq(other_value)
    end

    it 'rejects promise2 with error raised by on_fulfill' do
      promise2 = subject.then(proc { |_| raise error })
      subject.fulfill(value)

      expect(promise2).to be_rejected
      expect(promise2.reason).to eq(error)
    end

    it 'rejects promise2 with error raised by on_reject' do
      promise2 = subject.then(nil, proc { |_| raise error })
      subject.reject(reason)

      expect(promise2).to be_rejected
      expect(promise2.reason).to eq(error)
    end

    describe 'on_fulfill returns promise' do
      it 'makes promise2 assume fulfilled state of returned promise' do
        promise2 = subject.then(proc { |_| returned_promise })

        subject.fulfill(value)
        expect(promise2).to be_pending

        returned_promise.fulfill(other_value)
        expect(promise2).to be_fulfilled
        expect(promise2.value).to eq(other_value)
      end

      it 'makes promise2 assume rejected state of returned promise' do
        promise2 = subject.then(proc { |_| returned_promise })

        subject.fulfill(value)
        expect(promise2).to be_pending

        returned_promise.reject(other_reason)
        expect(promise2).to be_rejected
        expect(promise2.reason).to eq(other_reason)
      end
    end

    describe 'on_reject returns promise' do
      it 'makes promise2 assume fulfilled state of returned promise' do
        promise2 = subject.then(nil, proc { |_| returned_promise })

        subject.reject(reason)
        expect(promise2).to be_pending

        returned_promise.fulfill(other_value)
        expect(promise2).to be_fulfilled
        expect(promise2.value).to eq(other_value)
      end

      it 'makes promise2 assume rejected state of returned promise' do
        promise2 = subject.then(nil, proc { |_| returned_promise })

        subject.reject(reason)
        expect(promise2).to be_pending

        returned_promise.reject(other_reason)
        expect(promise2).to be_rejected
        expect(promise2.reason).to eq(other_reason)
      end
    end

    describe 'without on_fulfill' do
      it 'fulfill promise2 with fulfillment value' do
        promise2 = subject.then
        subject.fulfill(value)

        expect(promise2).to be_fulfilled
        expect(promise2.value).to eq(value)
      end
    end

    describe 'without on_reject' do
      it 'rejects promise2 with rejection reason' do
        promise2 = subject.then
        subject.reject(reason)

        expect(promise2).to be_rejected
        expect(promise2.reason).to eq(reason)
      end
    end
  end

  describe '#fulfill' do
    describe 'when called on a pending Promise' do
      it 'fulfills the Promise with the given value' do
        promise = Promise.new
        promise.fulfill(:foo)

        expect(promise).to be_fulfilled
        expect(promise.value).to equal(:foo)
      end

      it 'can be called without arguments' do
        promise = Promise.new
        promise.fulfill

        expect(promise).to be_fulfilled
        expect(promise.value).to be_nil
      end

      it 'returns self on a pending promise' do
        promise = Promise.new
        expect(promise.fulfill(:foo)).to equal(promise)
      end

      it 'returns self on a rejected promise' do
        promise = Promise.new
        promise.reject(:baz)
        expect(promise.fulfill(:foo)).to equal(promise)
      end

      it 'unsets any `source` associations' do
        other = Promise.new

        promise = Promise.new
        promise.fulfill(other)

        other.fulfill(:foo)

        expect(promise.source).to be_nil
      end

      it 'unsets any references to previously set observers' do
        promise = Promise.new

        observer = Class.new { include Promise::Observer }.new
        promise.subscribe(observer, nil, nil)

        promise.fulfill(:foo)

        expect(promise.instance_variable_get(:@observers)).to be_nil
      end
    end

    describe 'when called on a fulfilled Promise' do
      it 'returns self' do
        promise = Promise.new
        promise.fulfill(:foo)

        expect(promise.fulfill(:bar)).to equal(promise)
      end

      it 'can not change the fulfillment value' do
        promise = Promise.new
        promise.fulfill(:foo)
        promise.fulfill(:bar)

        expect(promise).to be_fulfilled
        expect(promise.value).to equal(:foo)
      end
    end

    describe 'when called on a rejected Promise' do
      it 'returns self' do
        promise = Promise.new
        promise.reject(:foo)

        expect(promise.fulfill(:bar)).to equal(promise)
      end

      it 'can not change the rejection reason' do
        promise = Promise.new
        promise.reject(:foo)
        promise.fulfill(:bar)

        expect(promise).to be_rejected
        expect(promise.reason).to equal(:foo)
      end

      it 'does not set a fulfilment value' do
        promise = Promise.new
        promise.reject(:foo)
        promise.fulfill(:bar)

        expect(promise.value).to be_nil
      end
    end

    describe 'when the fulfillment value is a pending Promise' do
      it 'leaves the promise in a pending state' do
        other = Promise.new

        promise = Promise.new
        promise.fulfill(other)

        expect(promise).to be_pending
      end

      it 'sets the given Promise as the source' do
        other = Promise.new

        promise = Promise.new
        promise.fulfill(other)

        expect(promise.source).to equal(other)
      end

      it 'propagates promise fulfillment' do
        other = Promise.new

        promise = Promise.new
        promise.fulfill(other)

        other.fulfill(:foo)

        expect(promise).to be_fulfilled
        expect(promise.value).to equal(:foo)
      end

      it 'propagates promise rejection' do
        other = Promise.new

        promise = Promise.new
        promise.fulfill(other)

        other.reject(:foo)

        expect(promise).to be_rejected
        expect(promise.reason).to equal(:foo)
      end
    end

    describe 'when the fulfillment value is a fulfilled Promise' do
      it 'fulfills the Promise with the same value' do
        other = Promise.new
        other.fulfill(:foo)

        promise = Promise.new
        promise.fulfill(other)

        expect(promise).to be_fulfilled
        expect(promise.value).to equal(:foo)
      end

      it 'works with Promise subclasses' do
        other = Class.new(Promise).new
        other.fulfill(:foo)

        promise = Promise.new
        promise.fulfill(other)

        expect(promise).to be_fulfilled
        expect(promise.value).to equal(:foo)
      end
    end

    describe 'when the fulfillment value is a rejected Promise' do
      it 'fulfills the Promise with the same value' do
        other = Promise.new
        other.reject(:foo)

        promise = Promise.new
        promise.fulfill(other)

        expect(promise).to be_rejected
        expect(promise.reason).to equal(:foo)
      end

      it 'works with Promise subclasses' do
        other = Class.new(Promise).new
        other.reject(:foo)

        promise = Promise.new
        promise.fulfill(other)

        expect(promise).to be_rejected
        expect(promise.reason).to equal(:foo)
      end
    end
  end

  describe '#reject' do
    describe 'when called on a pending Promise' do
      it 'rejects the Promise with the given value' do
        promise = Promise.new
        promise.reject(:foo)

        expect(promise).to be_rejected
        expect(promise.reason).to equal(:foo)
      end

      it 'can be called without arguments' do
        promise = Promise.new
        promise.reject

        expect(promise).to be_rejected
        expect(promise.reason).to be_an_instance_of(Promise::Error)
      end

      it 'returns self' do
        promise = Promise.new
        expect(promise.reject(:foo)).to equal(promise)
      end

      it 'unsets any `source` associations' do
        other = Promise.new

        promise = Promise.new
        promise.fulfill(other)

        other.reject(:foo)

        expect(promise.source).to be_nil
      end

      it 'unsets any references to previously set observers' do
        promise = Promise.new

        observer = Class.new { include Promise::Observer }.new
        promise.subscribe(observer, nil, nil)

        promise.reject(:foo)

        expect(promise.instance_variable_get(:@observers)).to be_nil
      end
    end

    describe 'when called on a fulfilled Promise' do
      it 'returns self' do
        promise = Promise.new
        promise.fulfill(:foo)

        expect(promise.reject(:bar)).to equal(promise)
      end

      it 'can not change the fulfillment value' do
        promise = Promise.new
        promise.fulfill(:foo)
        promise.reject(:bar)

        expect(promise).to be_fulfilled
        expect(promise.value).to equal(:foo)
      end

      it 'does not set a rejection reason' do
        promise = Promise.new
        promise.fulfill(:foo)
        promise.reject(:bar)

        expect(promise.reason).to be_nil
      end
    end

    describe 'when called on a rejected Promise' do
      it 'returns self' do
        promise = Promise.new
        promise.reject(:foo)

        expect(promise.reject(:bar)).to equal(promise)
      end

      it 'can not change the rejection reason' do
        promise = Promise.new
        promise.reject(:foo)
        promise.reject(:bar)

        expect(promise).to be_rejected
        expect(promise.reason).to equal(:foo)
      end
    end
  end

  describe '#subscribe' do
    it 'sets up the observer to be notified of promise fulfillment' do
      promise = Promise.new

      observer = Class.new { include Promise::Observer }.new
      promise.subscribe(observer, :fulfill_arg, :reject_arg)

      expect(observer).to receive(:promise_fulfilled).with(:foo, :fulfill_arg)
      promise.fulfill(:foo)
    end

    it 'sets up the observer to be notified of promise rejection' do
      promise = Promise.new

      observer = Class.new { include Promise::Observer }.new
      promise.subscribe(observer, :fulfill_arg, :reject_arg)

      expect(observer).to receive(:promise_rejected).with(:foo, :reject_arg)
      promise.reject(:foo)
    end

    it 'fails when called on a fulfilled promise' do
      promise = Promise.new
      promise.fulfill(:foo)

      observer = Class.new { include Promise::Observer }.new

      expected_message = 'Non-pending promises can not be observed'
      expect {
        promise.subscribe(observer, :fulfill_arg, :reject_arg)
      }.to raise_error(Promise::Error, expected_message)
    end

    it 'fails when called on a rejected promise' do
      promise = Promise.new
      promise.reject(:foo)

      observer = Class.new { include Promise::Observer }.new

      expected_message = 'Non-pending promises can not be observed'
      expect {
        promise.subscribe(observer, :fulfill_arg, :reject_arg)
      }.to raise_error(Promise::Error, expected_message)
    end

    it 'fails when the given observer is not a `Promise::Observer`' do
      promise = Promise.new

      observer = Object.new

      expected_message = 'Expected `observer` to be a `Promise::Observer`'
      expect {
        promise.subscribe(observer, :fulfill_arg, :reject_arg)
      }.to raise_error(ArgumentError, expected_message)
    end
  end

  describe 'extras' do
    describe '#rescue' do
      it 'provides an on_reject callback' do
        result = nil
        subject.rescue { |reas| result = reas }

        subject.reject(reason)
        expect(result).to eq(reason)
        expect(subject.reason).to eq(reason)
      end
    end

    describe '#catch' do
      it 'provides an on_reject callback' do
        result = nil
        subject.catch { |reas| result = reas }

        subject.reject(reason)
        expect(result).to eq(reason)
        expect(subject.reason).to eq(reason)
      end
    end

    describe '#progress' do
      let(:status) { double('status') }

      it 'calls the callbacks in the order of calls to #on_progress' do
        order = []
        block = proc do |i, stat|
          order << i
          expect(stat).to eq(status)
        end

        subject.on_progress(&block.curry[1])
        subject.on_progress(&block.curry[2])
        subject.on_progress(&block.curry[3])
        subject.progress(status)

        expect(order).to eq([1, 2, 3])
      end

      it 'does not call back unless pending' do
        called = false
        subject.on_progress { |_| called = true }
        subject.fulfill(value)

        subject.progress(status)
        expect(called).to eq(false)
      end
    end

    describe '#fulfill' do
      it 'returns itself to allow chaining' do
        expect(subject.fulfill(nil)).to be(subject)
      end

      it 'does not require a value' do
        subject.fulfill
        expect(subject.value).to be(nil)
      end

      it 'assumes the state of a given promise' do
        promise = Promise.new

        subject.fulfill(promise)
        expect(subject).to be_pending
        promise.fulfill(123)

        expect(subject).to be_fulfilled
        expect(subject.value).to eq(123)
      end
    end

    describe '#reject' do
      it 'returns itself for easy chaning' do
        expect(subject.reject(nil)).to be(subject)
      end

      it 'does not require a reason' do
        subject.reject
        expect(subject.reason).to be_a(Promise::Error)
      end

      it 'sets the backtrace' do
        subject.reject
        expect(subject.reason.backtrace.join)
          .to include(__FILE__ + ':' + (__LINE__ - 2).to_s)
      end

      it 'leaves backtrace if already set' do
        subject.reject(reason)
        expect(subject.reason.backtrace).to eq(backtrace)
      end

      it 'instantiates exception class' do
        subject.reject(Exception)
        expect(subject.reason).to be_a(Exception)
      end

      it 'instantiates exception subclasses' do
        subject.reject(RuntimeError)
        expect(subject.reason).to be_a(RuntimeError)
      end

      it "doesn't instantiate non-error classes" do
        subject.reject(Hash)
        expect(subject.reason).to eq(Hash)
      end
    end

    describe '#sync' do
      it 'waits for fulfillment' do
        allow(subject).to receive(:wait) { subject.fulfill(value) }
        expect(subject.sync).to be(value)
      end

      it 'waits for rejection' do
        allow(subject).to receive(:wait) { subject.reject(reason) }
        expect { subject.sync }.to raise_error(reason)
      end

      it 'waits if pending' do
        subject.fulfill(value)
        expect(subject).not_to receive(:wait)
        expect(subject.sync).to be(value)
      end

      it 'waits for source by default' do
        PromiseLoader.lazy_load(subject) { subject.fulfill(1) }
        p2 = subject.then { |v| v + 1 }
        expect(p2).to be_pending
        expect(p2.sync).to eq(2)
        expect(p2.source).to eq(nil)
      end

      it 'waits for source that is fulfilled with a promise' do
        PromiseLoader.lazy_load(subject) { subject.fulfill(1) }
        p2 = subject.then do |v|
          Promise.new.tap do |p3|
            PromiseLoader.lazy_load(p3) { p3.fulfill(v + 1) }
          end
        end
        expect(p2).to be_pending
        expect(p2.sync).to eq(2)
        expect(p2.source).to eq(nil)
      end

      it 'waits for source rejection' do
        PromiseLoader.lazy_load(subject) { subject.reject(reason) }
        p2 = subject.then { |v| v + 1 }
        expect { p2.sync }.to raise_error(reason)
        expect(p2.source).to eq(nil)
      end

      it 'raises for promise without a source by default' do
        expect { subject.sync }.to raise_error(Promise::BrokenError)
      end

      it 'raises if source.wait leaves promise pending' do
        PromiseLoader.lazy_load(subject) {}
        expect { subject.sync }.to raise_error(Promise::BrokenError)
      end
    end

    describe '.sync' do
      it 'returns non-promise argument' do
        expect(Promise.sync(42)).to eq(42)
      end

      it 'calls sync on promise argument' do
        PromiseLoader.lazy_load(subject) { subject.fulfill(123) }
        expect(Promise.sync(subject)).to eq(123)
      end

      it 'calls sync on promise of another class' do
        promise = Class.new(Promise).resolve('a')
        expect(Class.new(Promise).sync(promise)).to eq('a')
      end
    end

    describe '.resolve' do
      it 'returns a fulfilled promise from a non-promise' do
        promise = Promise.resolve(123)
        expect(promise.fulfilled?).to eq(true)
        expect(promise.value).to eq(123)
      end

      it 'returns a given promise' do
        promise = Promise.new
        new_promise = Promise.resolve(promise)
        expect(new_promise.object_id).to eq(promise.object_id)
      end

      it 'returns a given promise of a subclass of itself' do
        promise = DelayedPromise.new
        new_promise = Promise.resolve(promise)
        expect(new_promise.object_id).to eq(promise.object_id)
      end

      it 'assumes the state of a given promise of another class' do
        promise = Promise.new
        new_promise = DelayedPromise.resolve(promise)
        expect(new_promise).to be_an_instance_of(DelayedPromise)
        expect(new_promise).to be_pending
        promise.fulfill(42)
        expect(new_promise).to be_fulfilled
        expect(new_promise.value).to eq(42)
      end

      it 'can be passed no argument' do
        promise = Promise.resolve
        expect(promise.fulfilled?).to eq(true)
        expect(promise.value).to eq(nil)
      end
    end

    describe '.all' do
      it "fulfills the result with inputs if they don't contain promises" do
        input = [1, 'b']
        promise = Promise.all(input)

        expect(promise).to be_fulfilled
        expect(promise.value).to eq([1, 'b'])
      end

      it 'fulfills the result when all args are already fulfilled' do
        input = [1, Promise.resolve(2.0)]
        promise = Promise.all(input)

        expect(promise).to be_fulfilled
        expect(promise.value).to eq([1, 2.0])
      end

      it 'fulfills the result when all args are fulfilled' do
        p1 = Promise.new
        p2 = Promise.new

        result = Promise.all([p1, p2, 3])

        expect(result).to be_pending
        p2.fulfill('b')
        expect(result).to be_pending
        p1.fulfill(:a)
        expect(result).to be_fulfilled
        expect(result.value).to eq([:a, 'b', 3])
      end

      it 'leaves result pending if only the first input arg is fulfilled' do
        p1 = Promise.new
        p1.fulfill('a')
        p2 = Promise.new

        result = Promise.all([p1, p2])

        expect(result).to be_pending
        p2.fulfill(:b)
        expect(result).to be_fulfilled
        expect(result.value).to eq(['a', :b])
      end

      it 'rejects the result when any input promise is already rejected' do
        p1 = Promise.new
        p2 = Promise.new.reject(:foo)

        result = Promise.all([p1, p2])

        expect(result).to be_rejected
        expect(result.reason).to eq(:foo)
      end

      it 'rejects the result when any args is rejected' do
        p1 = Promise.new
        p2 = Promise.new
        reason = RuntimeError.new('p1 failed')

        result = Promise.all([p1, p2])

        expect(result).to be_pending
        p1.reject(reason)
        expect(result).to be_rejected
        expect(result.reason).to eq(reason)
      end

      it 'returns an instance of the class it is called on' do
        p1 = Promise.new

        result = DelayedPromise.all([p1, 2])

        expect(result).to be_an_instance_of(DelayedPromise)
        p1.fulfill(1.0)
        expect(result.sync).to eq([1.0, 2])
      end

      it 'returns an instance of the class it is called on' do
        p1 = DelayedPromise.new

        result = DelayedPromise.all([p1, 2])

        expect(result).to be_pending
        p1.fulfill(1.0)
        expect(result.sync).to eq([1.0, 2])
      end

      it 'returns a promise that can sync promises of another class' do
        p1 = DelayedPromise.new
        DelayedPromise.deferred << -> { p1.fulfill('a') }

        result = Promise.all([p1, Promise.resolve(:b), 3])

        expect(result).to be_pending
        expect(result.sync).to eq(['a', :b, 3])
      end

      it 'sync on result does not call wait on resolved promises' do
        p1 = Class.new(Promise) do
          def wait
            raise 'wait not expected'
          end
        end.resolve(:one)
        p2 = DelayedPromise.new
        DelayedPromise.deferred << -> { p2.fulfill(:two) }

        result = Promise.all([p1, p2])

        expect(result.sync).to eq([:one, :two])
      end
    end

    describe '.map_value' do
      it "yields the argument directly if it isn't a promise" do
        p = Promise.map_value(2) { |v| v + 1 }
        expect(p).to eq(3)
      end

      it 'uses .then on a promise argument using the given block' do
        p = Promise.map_value(Promise.resolve(2)) { |v| v + 1 }
        expect(p.sync).to eq(3)
      end

      it 'uses .then on a promise argument of another class' do
        p1 = Class.new(Promise).resolve(2)
        p2 = DelayedPromise.map_value(p1) { |v| v + 1 }
        expect(p2.sync).to eq(3)
      end
    end
  end
end
