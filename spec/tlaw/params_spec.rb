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
    end
  end
end
