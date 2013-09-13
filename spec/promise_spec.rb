require 'spec_helper'

describe Promise, '#then' do
  subject { Promise.new }

  let(:value) { double('value') }
  let(:reason) { double('reason') }

  describe '3.2.1' do
    specify 'on_fulfill is optional' do
      subject.then
      subject.fulfill(value)
    end

    specify 'on_reject is optional' do
      subject.then(proc { |_| })
      subject.reject(reason)
    end
  end

  describe '3.2.2' do
    specify 'on_fulfill is called after promise is fulfilled' do
      state = nil
      subject.then(proc { |_| state = subject.state })

      subject.fulfill(value)
      expect(state).to eq(:fulfilled)
    end

    specify 'on_fulfill is called with fulfillment value' do
      result = nil
      subject.then(proc { |val| result = val })

      subject.fulfill(value)
      expect(result).to eq(value)
    end

    specify 'on_fulfill is called not more than once' do
      called = 0
      subject.then(proc { |_| called += 1 })

      subject.fulfill(value)
      subject.fulfill(value)
      expect(called).to eq(1)
    end

    specify 'on_fulfill is not called if on_reject has been called' do
      called = false
      subject.then(proc { |_| called = true })

      subject.reject(reason)
      expect(called).to eq(false)
    end
  end
end
