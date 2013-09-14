# encoding: utf-8

require 'spec_helper'

describe Promise do
  subject { Promise.new }

  let(:value) { double('value') }
  let(:other_value) { double('other_value') }
  let(:reason) { double('reason') }
  let(:other_reason) { double('other_reason') }

  describe '#state' do
    describe '3.1.1 pending' do
      it 'transitions to fulfilled' do
        subject.fulfill(value)
        expect(subject.state).to eq(:fulfilled)
      end

      it 'transitions to rejected' do
        subject.reject(reason)
        expect(subject.state).to eq(:rejected)
      end
    end

    describe '3.1.2 fulfilled' do
      it 'does not transition to other states' do
        subject.fulfill(value)
        subject.reject(reason)
        expect(subject.state).to eq(:fulfilled)
      end

      it 'has an immutable value' do
        subject.fulfill(value)
        expect(subject.value).to eq(value)

        subject.fulfill(other_value)
        expect(subject.value).to eq(value)

        expect(subject.value).to be_frozen
      end
    end

    describe '3.1.3 fulfilled' do
      it 'does not transition to other states' do
        subject.reject(reason)
        subject.fulfill(value)
        expect(subject.state).to eq(:rejected)
      end

      it 'has an immutable value' do
        subject.reject(reason)
        expect(subject.reason).to eq(reason)

        subject.reject(other_reason)
        expect(subject.reason).to eq(reason)

        expect(subject.reason).to be_frozen
      end
    end
  end

  describe '#then' do
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
        state = nil
        subject.then(proc { |_| state = subject.state })

        subject.fulfill(value)
        expect(state).to eq(:fulfilled)
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
    end

    describe '3.2.3 on_reject' do
      it 'is called after promise is rejected' do
        state = nil
        subject.then(nil, proc { |_| state = subject.state })

        subject.reject(reason)
        expect(state).to eq(:rejected)
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
      it 'returns before on_fulfill or on_reject is called' do
        pending
      end
    end
  end
end
