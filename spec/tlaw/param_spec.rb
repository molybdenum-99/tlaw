module TLAW
  module Params
    describe Base do
      describe '#convert' do
        subject { param.convert(value) }

        context 'default' do
          let(:param) { described_class.new(:p) }
          let(:value) { double }

          it { is_expected.to eq value }
        end

        context 'by duck type' do
          let(:param) { described_class.new(:p, type: :to_time) }

          context 'when responds' do
            let(:value) { double(to_time: 'value') }

            it { is_expected.to eq 'value' }
          end

          context 'when not' do
            let(:value) { double }

            its_block { is_expected.to raise_error Nonconvertible }
          end
        end

        context 'by class' do
          let(:param) { described_class.new(:p, type: Time) }

          context 'when corresponds' do
            let(:value) { Time.now }

            it { is_expected.to eq value }
          end

          xcontext 'when coercible'

          context 'when non-coercible' do
            let(:value) { 'test' }

            its_block { is_expected.to raise_error Nonconvertible }
          end
        end

        context 'hash enum' do
          let(:param) { described_class.new(:p, enum: {true => 'yes', false => 'no'}) }

          context 'when included' do
            let(:value) { true }

            it { is_expected.to eq 'yes' }
          end

          context 'when not' do
            let(:value) { 'foo' }

            its_block { is_expected.to raise_error Nonconvertible }
          end
        end

        context 'integer enum' do
          let(:param) { described_class.new(:p, enum: 1..100) }

          context 'when included' do
            let(:value) { 42 }

            it { is_expected.to eq 42 }
          end

          context 'when not an integer' do
            let(:value) { 42.5 }

            its_block { is_expected.to raise_error Nonconvertible }
          end

          context 'when not in range' do
            let(:value) { 0 }

            its_block { is_expected.to raise_error Nonconvertible }
          end
        end

        context 'float enum' do
          let(:param) { described_class.new(:p, enum: 0.0..1.0) }

          context 'when included' do
            let(:value) { 0.42 }

            it { is_expected.to eq 0.42 }
          end

          context 'when is an integer in range' do
            let(:value) { 0 }

            it { is_expected.to eq 0 }
          end

          context 'when not in range' do
            let(:value) { 2.0 }

            its_block { is_expected.to raise_error Nonconvertible }
          end
        end
      end

      describe '#format' do
        let(:param) { described_class.new(:p) }

        subject { param.format(value) }

        context 'default: to_s' do
          let(:value) { double(to_s: 'value') }

          it { is_expected.to eq 'value' }
        end

        context 'default: arrays' do
          let(:value) { [1, 2, 3, :foo] }

          it { is_expected.to eq '1,2,3,foo' }
        end

        context 'with lambda' do
          let(:param) { described_class.new(:p, format: ->(v) { v + 1 }) }
          let(:value) { 5 }

          it { is_expected.to eq '6' }
        end

        context 'with symbol' do
          let(:param) { described_class.new(:p, format: :to_i) }
          let(:value) { 5.5 }

          it { is_expected.to eq '5' }
        end

        context 'unformattable'
      end

      describe '#convert_and_format' do
        let(:param) { described_class.new(:p, type: :to_i, format: ->(x) { x * 2 }) }

        specify { expect(param.convert_and_format(3.3)).to eq '6' }
      end

      describe '#merge' do
        let(:param) { Params.make(:p, required: true) }

        subject { param.merge(default: 5) }

        its(:name) { is_expected.to eq :p }
        it { is_expected.to be_a Keyword }
        it { is_expected.to be_required }
        its(:default) { is_expected.to eq 5 }
        its(:object_id) { is_expected.not_to eq param.object_id }

        context 'when non-keyword param' do
          subject { param.merge(default: 5, keyword: false) }

          it { is_expected.to be_a Argument }

          context 'with class change' do
            subject { param.merge(default: 5, keyword: true) }

            it { is_expected.to be_a Keyword }
          end
        end
      end

      describe '#to_code' do
        subject { param.to_code }

        context 'keyword - required' do
          let(:param) { Params.make(:p, required: true) }

          it { is_expected.to eq 'p:' }
        end

        context 'keyword - optional' do
          let(:param) { Params.make(:p) }

          it { is_expected.to eq 'p: nil' }
        end

        context 'keyword - with default' do
          let(:param) { Params.make(:p, default: 'foo') }

          it { is_expected.to eq 'p: "foo"' }
        end

        context 'argument - required' do
          let(:param) { Params.make(:p, keyword: false, required: true) }

          it { is_expected.to eq 'p' }
        end

        context 'argument - optional' do
          let(:param) { Params.make(:p, keyword: false) }

          it { is_expected.to eq 'p=nil' }
        end

        context 'argument - with default' do
          let(:param) { Params.make(:p, keyword: false, default: 'foo') }

          it { is_expected.to eq 'p="foo"' }
        end
      end

      describe '#type' do
        it 'raises an ArgumentError on bad argument' do
          expect { described_class.new(:p, type: 'hello') }.to raise_error(ArgumentError, 'Undefined type hello')
        end
      end

      describe '#describe' do
        subject { param.describe }

        context 'simplest' do
          let(:param) { described_class.new(:p, type: :to_i) }

          it { is_expected.to eq '@param p [#to_i]' }
        end

        context 'with description' do
          let(:param) { described_class.new(:p, type: :to_i, description: 'Foo bar') }

          it { is_expected.to eq '@param p [#to_i] Foo bar' }
        end

        context 'description synonym' do
          let(:param) { described_class.new(:p, type: :to_i, desc: 'Foo bar') }

          it { is_expected.to eq '@param p [#to_i] Foo bar' }
        end

        context 'default value' do
          let(:param) { described_class.new(:p, type: :to_i, desc: 'Foo bar', default: 8) }

          it { is_expected.to eq '@param p [#to_i] Foo bar (default = 8)' }
        end

        context 'enum' do
          context 'hash' do
            let(:param) { described_class.new(:p, enum: {true => 'foo', false => 'bar'}) }

            it { is_expected.to include('Possible values: true, false') }
          end

          context 'hash via type' do
            let(:param) { described_class.new(:p, type: {true => 'foo', false => 'bar'}) }

            it { is_expected.to include('Possible values: true, false') }
          end

          context 'range' do
            let(:param) { described_class.new(:p, enum: 1..100) }

            it { is_expected.to include('Possible values: 1..100') }
          end

          context 'other enumerable' do
            let(:param) { described_class.new(:p, enum: %w[foo bar]) }

            it { is_expected.to include('Possible values: "foo", "bar"') }
          end
        end
      end
    end
  end
end
