module TLAW
  describe Endpoint do
    describe '.add_param' do
    end

    describe '#call' do
      let(:api) { instance_double('TLAW::API') }
      let(:endpoint_class) { Class.new(Endpoint) { self.path = 'weather' } }
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
    end
  end
end
