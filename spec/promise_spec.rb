require 'spec_helper'

describe Promise, '#then' do
  subject { Promise.new }

  let(:value) { double('value') }
  let(:reason) { double('reason') }

  describe '3.2.1' do
    specify 'on_fulfill is optional' do
      result = nil
      subject.then(nil, proc {|r| result = r })

      subject.reject(reason)
      expect(result).to eq(reason)
    end
  end
end
