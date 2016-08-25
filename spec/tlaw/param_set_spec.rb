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
      end
    end

    describe '#process'

    context 'docs' do
      before {
        set.add :kv1, type: Time
        set.add :kv2, type: :to_i, required: true
        set.add :kv3, default: 14

        set.add :arg1, keyword_argument: false
        set.add :arg2, keyword_argument: false, default: 'foo'
        set.add :arg3, type: :to_time, keyword_argument: false, required: true

        set.add :cm1, common: true
      }

      describe '#definition' do
        subject { set.definition }

        it { is_expected.to  eq 'arg3, arg1=nil, arg2="foo", kv2:, kv1: nil, kv3: 14' }
      end

      describe '#description' do
        subject { set.description }

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
