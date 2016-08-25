module TLAW
  describe Param do
    describe '#required?' do
    end

    describe '#convert' do
      subject { param.convert(value) }

      context 'default' do
        let(:param) { Param.new(:p) }
        let(:value) { double }
        it { is_expected.to eq value }
      end

      context 'by duck type' do
        let(:param) { Param.new(:p, type: :to_time) }

        context 'when responds' do
          let(:value) { double(to_time: 'value') }
          it { is_expected.to eq 'value' }
        end

        context 'when not' do
          let(:value) { double }
          specify { expect { subject }.to raise_error Param::Nonconvertible }
        end
      end

      context 'by class' do
        let(:param) { Param.new(:p, type: Time) }

        context 'when corresponds' do
          let(:value) { Time.now }
          it { is_expected.to eq value }
        end

        xcontext 'when coercible'

        context 'when non-coercible' do
          let(:value) { 'test' }
          specify { expect { subject }.to raise_error Param::Nonconvertible }
        end
      end

      context 'enum' do
      end
    end

    describe '#format' do
      let(:param) { Param.new(:p) }
      subject { param.format(value) }

      context 'default: to_s' do
        let(:value) { double(to_s: 'value') }

        it { is_expected.to eq 'value' }
      end

      context 'default: arrays' do
        let(:value) { [1,2,3,:foo] }

        it { is_expected.to eq '1,2,3,foo' }
      end

      context 'with lambda' do
        let(:param) { Param.new(:p, format: ->(v) { v + 1 } ) }
        let(:value) { 5 }

        it { is_expected.to eq '6' }
      end

      context 'with symbol' do
        let(:param) { Param.new(:p, format: :to_i) }
        let(:value) { 5.5 }

        it { is_expected.to eq '5' }
      end

      context 'unformattable'
    end

    describe '#convert_and_format' do
      let(:param) { Param.new(:p, type: :to_i, format: ->(x) { x*2 }) }
      specify { expect(param.convert_and_format(3.3)).to eq '6' }
    end

    describe '#generate_definition' do
      subject { param.to_code }

      context 'keyword - required' do
        let(:param) { Param.new(:p, required: true) }
        it { is_expected.to eq 'p:' }
      end

      context 'keyword - optional' do
        let(:param) { Param.new(:p) }
        it { is_expected.to eq 'p: nil' }
      end

      context 'keyword - with default' do
        let(:param) { Param.new(:p, default: 'foo') }
        it { is_expected.to eq 'p: "foo"' }
      end

      context 'argument - required' do
        let(:param) { Param.new(:p, keyword_argument: false, required: true) }
        it { is_expected.to eq 'p' }
      end

      context 'argument - optional' do
        let(:param) { Param.new(:p, keyword_argument: false) }
        it { is_expected.to eq 'p=nil' }
      end

      context 'argument - with default' do
        let(:param) { Param.new(:p, keyword_argument: false, default: "foo") }
        it { is_expected.to eq 'p="foo"' }
      end
    end
  end
end
