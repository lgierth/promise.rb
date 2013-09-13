require 'spec_helper'

describe Promise, '#then' do
  subject { Promise.new }

  let(:value) { double('value') }
  let(:reason) { double('reason') }

  let(:on_fulfill) do
    proc { |value| @value = value }
  end
  let(:on_reject) do
    proc { |reason| @reason = reason }
  end

  describe '3.2.1' do
    specify 'on_fulfill is optional' do
      subject.then
      subject.fulfill(value)
    end

    specify 'on_reject is optional' do
      subject.then(on_fulfill)
      subject.reject(reason)
    end
  end
end
