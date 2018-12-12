require 'tlaw/params/param'

RSpec.describe TLAW::Params do
  describe '#call' do
    let(:params) {
      described_class.new(
        TLAW::Params::Param.new(name: :a, required: true),
        TLAW::Params::Param.new(name: :b, type: Integer, field: :bb),
        TLAW::Params::Param.new(name: :c, format: ->(t) { t.strftime('%Y-%m-%d') })
      )
    }

    subject { params.method(:call) }

    its_call(a: 1, b: 2, c: Time.parse('2017-05-01')) {
      is_expected.to ret(a: '1', bb: '2', c: '2017-05-01')
    }

    its_call(b: 2) {
      is_expected.to raise_error(ArgumentError, 'Missing arguments: a')
    }
    its_call(a: 1, d: 2) {
      is_expected.to raise_error(ArgumentError, 'Unknown arguments: d')
    }
    its_call(a: 1, b: 'test') {
      is_expected.to raise_error(TypeError, 'b: expected instance of Integer, got "test"')
    }
  end
end
