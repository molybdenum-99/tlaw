module TLAW
  describe Param do
    describe '.make' do
      context 'default' do
        subject { described_class.make(:foo) }
        it { is_expected.to be_a KeywordParam }
      end

      context 'non-keyword' do
        subject { described_class.make(:bar, keyword: false) }
        it { is_expected.to be_a ArgumentParam }
      end
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
        let(:param) { Param.new(:p, enum: {true => 'yes', false => 'no'}) }

        context 'when included' do
          let(:value) { true }
          it { is_expected.to eq 'yes' }
        end

        context 'when not' do
          let(:value) { 'foo' }
          it { expect { subject }.to raise_error Param::Nonconvertible }
        end
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

    describe '#merge' do
      let(:param) { described_class.make(:p, required: true) }
      subject { param.merge(default: 5) }

      its(:name) { is_expected.to eq :p }
      it { is_expected.to be_a KeywordParam }
      it { is_expected.to be_required }
      its(:default) { is_expected.to eq 5 }
      its(:object_id) { is_expected.not_to eq param.object_id }

      context 'when non-keyword param' do
        subject { param.merge(default: 5, keyword: false) }

        it { is_expected.to be_a ArgumentParam }

        context 'with class change' do
          subject { param.merge(default: 5, keyword: true) }

          it { is_expected.to be_a KeywordParam }
        end
      end
    end

    describe '#to_code' do
      subject { param.to_code }

      context 'keyword - required' do
        let(:param) { described_class.make(:p, required: true) }
        it { is_expected.to eq 'p:' }
      end

      context 'keyword - optional' do
        let(:param) { described_class.make(:p) }
        it { is_expected.to eq 'p: nil' }
      end

      context 'keyword - with default' do
        let(:param) { described_class.make(:p, default: 'foo') }
        it { is_expected.to eq 'p: "foo"' }
      end

      context 'argument - required' do
        let(:param) { described_class.make(:p, keyword: false, required: true) }
        it { is_expected.to eq 'p' }
      end

      context 'argument - optional' do
        let(:param) { described_class.make(:p, keyword: false) }
        it { is_expected.to eq 'p=nil' }
      end

      context 'argument - with default' do
        let(:param) { described_class.make(:p, keyword: false, default: "foo") }
        it { is_expected.to eq 'p="foo"' }
      end
    end

    describe '#describe' do
      subject { param.describe }

      context 'simplest' do
        let(:param) { Param.new(:p, type: :to_i) }
        it { is_expected.to eq '@param p [#to_i]' }
      end

      context 'with description' do
        let(:param) { Param.new(:p, type: :to_i, description: 'Foo bar') }
        it { is_expected.to eq '@param p [#to_i] Foo bar' }
      end

      context 'description synonym' do
        let(:param) { Param.new(:p, type: :to_i, desc: 'Foo bar') }
        it { is_expected.to eq '@param p [#to_i] Foo bar' }
      end

      context 'default value' do
        let(:param) { Param.new(:p, type: :to_i, desc: 'Foo bar', default: 8) }
        it { is_expected.to eq '@param p [#to_i] Foo bar (default = 8)' }
      end

      context 'enum' do
      end
    end
  end
end
