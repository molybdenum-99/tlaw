module TLAW
  describe ParamSet do
    let(:set) { described_class.new }

    describe '#add' do
      context 'when new' do
        before { set.add(:param1, type: Integer) }

        subject { set[:param1] }

        it { is_expected.to be_a Param }
        its(:name) { is_expected.to eq :param1 }
        its(:type) { is_expected.to eq Integer }
      end

      context 'when already exists' do
        before {
          set.add(:param1, type: Integer)
          set.add(:param1, required: true)
        }

        subject { set[:param1] }

        it { is_expected.to be_a Param }
        its(:name) { is_expected.to eq :param1 }
        its(:type) { is_expected.to eq Integer }
        it { is_expected.to be_required }

        context 'when type is changed on update' do
          before {
            set.add(:param1)
            set.add(:param1, keyword_argument: false)
          }

          subject { set[:param1] }
          it { is_expected.to be_a ArgumentParam }
        end
      end
    end

    describe '#process' do
      before {
        set.add(:param1, type: Integer)
        set.add(:param2, required: true)
      }

      it 'convert & format all the params' do
        expect(set[:param1]).to receive(:convert_and_format).with(:val1).and_return('val2')
        expect(set[:param2]).to receive(:convert_and_format).with(:val3).and_return('val4')
        expect(set.process(param1: :val1, param2: :val3)).to \
          eq(param1: 'val2', param2: 'val4')
      end

      it 'drops empty params' do
        expect(set[:param1]).not_to receive(:convert_and_format)
        expect(set[:param2]).to receive(:convert_and_format).with(:val3).and_return('val4')
        expect(set.process(param1: nil, param2: :val3)).to \
          eq(param2: 'val4')
      end

      it 'checks required params existance' do
        expect { set.process(param2: nil) }.to raise_error(ArgumentError, "Required parameter param2 is missing")
      end

      it 'fails on unknown params' do
        expect { set.process(param3: 'foo') }.to raise_error(ArgumentError, "Unknown parameters: param3")
      end

      context 'param renaming' do
        before {
          set.add(:param2, field: :foo)
        }

        it 'renames' do
          expect(set.process(param2: :val3)).to \
            eq(foo: 'val3')
        end
      end

      context 'parent scope' do
        let(:parent) { described_class.new }
        before {
          parent.add :param3
          set.parent = parent
        }
        it 'allows params from parent scope' do
          expect(set.process(param2: 1, param3: 'foo'))
            .to eq(param2: '1', param3: 'foo')
        end
      end
    end

    context 'docs' do
      before {
        set.add :kv1, type: Time
        set.add :kv2, type: :to_i, required: true
        set.add :kv3, default: 14

        set.add :arg1, keyword_argument: false
        set.add :arg2, keyword_argument: false, default: 'foo'
        set.add :arg3, type: :to_time, keyword_argument: false, required: true
      }

      describe '#definition' do
        subject { set.to_code }

        it { is_expected.to  eq 'arg3, arg1=nil, arg2="foo", kv2:, kv1: nil, kv3: 14' }
      end

      describe '#description' do
        subject { set.describe }

        it { is_expected.to be_a Util::Description }
        it { is_expected.to eq %Q{
          |@param arg3 [#to_time]
          |@param arg1 [#to_s]
          |@param arg2 [#to_s]
          |@param kv2 [#to_i]
          |@param kv1 [Time]
          |@param kv3 [#to_s]
        }.unindent }
      end
    end
  end
end
