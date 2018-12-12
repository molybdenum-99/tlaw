module TLAW
  describe Params do
    describe '.make' do
      context 'default' do
        subject { described_class.make(:foo) }

        it { is_expected.to be_a Params::Keyword }
      end

      context 'non-keyword' do
        subject { described_class.make(:bar, keyword: false) }

        it { is_expected.to be_a Params::Argument }
      end

      describe '#call' do
        let(:params) {
          described_class.new(
            Params::Param.new(name: :a, required: true),
            Params::Param.new(name: :b, type: Integer, field: :bb),
            Params::Param.new(name: :c, format: ->(t) { t.strftime('%Y-%m-%d') })
          )
        }

        subject { params.method(:call) }

        its_call(a: 1, b: 2, c: Time.parse('2017-05-01')) {
          is_expected.to ret(a: '1', b: '2', c: '2017-05-01')
        }

        its_call(b: 2) {
          is_expected.to raise_error(ArgumentError, 'Missing argument: a')
        }
        its_call(a: 1, b: 'test') {
          is_expected.to raise_error(ArgumentError, 'Wrong argument type: b')
        }
      end
    end
  end
end
