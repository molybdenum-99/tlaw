module TLAW
  describe DSL do
    describe DSL::APIWrapper do
      let!(:api) { Class.new(API) }
      let(:wrapper) { described_class.new(api) }

      describe '#define' do
        let(:block) { ->{} }
        it 'calls definition API' do
          expect(wrapper).to receive(:instance_eval){|&b| expect(b).to eq block }
          wrapper.define(&block)
        end
      end

      describe '#base' do
        let(:url) { Faker::Internet.url }

        it 'sets base url' do
          expect(api).to receive(:base_url=).with(url)
          wrapper.base url
        end
      end

      describe '#param' do
        it 'adds global parameter' do
          expect(api).to receive(:add_param).with(name: :param1, type: String, required: true)
          wrapper.param :param1, String, required: true
        end
      end

      describe '#endpoint' do
        let(:endpoint) { class_double('TLAW::Endpoint') }
        let(:endpoint_wrapper) { instance_double('TLAW::DSL::EndpointWrapper') }
        let(:block) { ->{} }

        it 'creates endpoint and adds it' do
          expect(Class).to receive(:new)
            .with(Endpoint).and_return(endpoint)

          expect(endpoint).to receive(:api=).with(api)
          expect(endpoint).to receive(:name=).with(:ep1)

          expect(DSL::EndpointWrapper).to receive(:new)
            .with(endpoint)
            .and_return(endpoint_wrapper)

          expect(endpoint_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(api).to receive(:add_endpoint).with(:ep1, endpoint)

          wrapper.endpoint :ep1, &block
        end
      end

    end

    describe DSL::EndpointWrapper do
      let(:endpoint) { Class.new(Endpoint) }
      let(:wrapper) { described_class.new(endpoint) }

      describe '#define' do
        let(:block) { ->{} }
        it 'calls definition API' do
          expect(wrapper).to receive(:instance_eval){|&b| expect(b).to eq block }
          wrapper.define(&block)
        end
      end

      describe '#param' do
        it 'creates params' do
          expect(endpoint).to receive(:add_param).with(name: :param1, type: String, required: true)
          wrapper.param :param1, String, required: true
        end
      end
    end
  end
end
