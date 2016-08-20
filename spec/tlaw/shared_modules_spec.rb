module TLAW
  describe Shared::ParamHolder do
    let(:host) { Class.new { extend Shared::ParamHolder } }

    describe '#add_param' do
      context 'when new' do
        before { host.add_param(:param1, type: Integer) }

        subject { host.params[:param1] }

        it { is_expected.to be_a Param }
        its(:name) { is_expected.to eq :param1 }
        its(:type) { is_expected.to eq Integer }
      end

      context 'when already exists' do
        before {
          host.add_param(:param1, type: Integer)
          host.add_param(:param1, required: true)
        }

        subject { host.params[:param1] }

        it { is_expected.to be_a Param }
        its(:name) { is_expected.to eq :param1 }
        its(:type) { is_expected.to eq Integer }
        it { is_expected.to be_required }
      end
    end
  end
end
