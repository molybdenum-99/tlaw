module TLAW
  describe Endpoint do
    describe '.add_param' do
    end

    describe '#call' do
      let(:api) { instance_double('TLAW::API') }
      let(:path) { 'weather' }
      let(:endpoint_class) { Class.new(Endpoint).tap { |c| c.path = path } }
      subject(:endpoint) { endpoint_class.new(api) }

      it 'validates & converts params'

      it 'calls back API with constructed URL' do
        expect(api).to receive(:call).with('/weather?q=Kharkiv')
        endpoint.call(q: 'Kharkiv')
      end

      context 'with namsepace' do
        it 'calls back API with constructed URL' do
          expect(api).to receive(:call).with('/boo/weather?q=Kharkiv')
          endpoint.call(q: 'Kharkiv', _namespace: 'boo')
        end
      end

      context 'URL constructions' do
        subject { endpoint.__send__(:construct_url, *args) }

        let(:params) { {} }
        let(:args) { [params] }

        context 'simple' do
          let(:params) { {lat: 0, lng: 0} }

          it { is_expected.to eq '/weather?lat=0&lng=0' }
        end

        context 'some param is part of path' do
          let(:path) { 'weather?q=:q' }
          let(:args) { ['Kharkiv'] }

          it { is_expected.to eq '/weather?q=Kharkiv' }
        end
      end
    end
  end
end
