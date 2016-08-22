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
          expect(api).to receive(:add_param)
            .with(:param1, type: String, required: true)
          wrapper.param :param1, String, required: true
        end
      end

      describe '#endpoint' do
        let(:endpoint) { class_double('TLAW::Endpoint') }
        let(:endpoint_wrapper) { instance_double('TLAW::DSL::EndpointWrapper') }
        let(:block) { ->{} }

        before {
          api.base_url = 'https://api.example.com'
          api.add_param :base_param1, type: Integer
        }

        it 'creates endpoint and adds it' do
          expect(Class).to receive(:new)
            .with(Endpoint).and_return(endpoint)

          expect(endpoint).to receive(:api=).with(api)
          expect(endpoint).to receive(:url=).with('https://api.example.com/ep1')
          expect(endpoint).to receive(:endpoint_name=).with(:ep1)

          expect(DSL::EndpointWrapper).to receive(:new)
            .with(endpoint)
            .and_return(endpoint_wrapper)

          expect(endpoint_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(endpoint).to receive(:add_param)
            .with(:base_param1, type: Integer, keyword_argument: true, common: true)

          expect(api).to receive(:add_endpoint).with(endpoint)

          wrapper.endpoint :ep1, &block
        end

        it 'allows explicit url' do
          expect(Class).to receive(:new)
            .with(Endpoint).and_return(endpoint)

          expect(endpoint).to receive(:api=).with(api)
          expect(endpoint).to receive(:url=).with('https://api.example.com/ns1/ns2/ep1')
          expect(endpoint).to receive(:endpoint_name=).with(:ep1)

          expect(DSL::EndpointWrapper).to receive(:new)
            .with(endpoint)
            .and_return(endpoint_wrapper)

          expect(endpoint_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(endpoint).to receive(:add_param)
            .with(:base_param1, type: Integer, keyword_argument: true, common: true)

          expect(api).to receive(:add_endpoint).with(endpoint)

          wrapper.endpoint :ep1, path: '/ns1/ns2/ep1', &block
        end

        it 'guesses params from url' do
          expect(Class).to receive(:new)
            .with(Endpoint).and_return(endpoint)

          expect(endpoint).to receive(:api=).with(api)
          expect(endpoint).to receive(:url=).with('https://api.example.com/ns1/ns2/{city}')
          expect(endpoint).to receive(:endpoint_name=).with(:ep1)
          expect(endpoint).to receive(:add_param).with(:city, keyword_argument: false)

          expect(DSL::EndpointWrapper).to receive(:new)
            .with(endpoint)
            .and_return(endpoint_wrapper)

          expect(endpoint_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(endpoint).to receive(:add_param)
            .with(:base_param1, type: Integer, keyword_argument: true, common: true)

          expect(api).to receive(:add_endpoint).with(endpoint)

          wrapper.endpoint :ep1, path: '/ns1/ns2/{city}', &block
        end
      end

      describe '#namespace' do
        let(:namespace) { class_double('TLAW::Namespace') }
        let(:namespace_wrapper) { instance_double('TLAW::DSL::NamespaceWrapper') }
        let(:block) { ->{} }

        before {
          api.base_url = 'https://api.example.com'
          api.add_param :base_param1, type: Integer
        }

        it 'creates namespace and adds it' do
          expect(Class).to receive(:new)
            .with(Namespace).and_return(namespace)

          expect(namespace).to receive(:api=).with(api)
          expect(namespace).to receive(:base_url=).with('https://api.example.com/ns1')
          expect(namespace).to receive(:namespace_name=).with(:ns1)

          expect(DSL::NamespaceWrapper).to receive(:new)
            .with(namespace)
            .and_return(namespace_wrapper)

          expect(namespace_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(namespace).to receive(:add_param)
            .with(:base_param1, type: Integer, keyword_argument: true, common: true)

          expect(api).to receive(:add_namespace).with(namespace)

          wrapper.namespace :ns1, &block
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
          expect(endpoint).to receive(:add_param).with(:param1, type: String, required: true)
          wrapper.param :param1, String, required: true
        end
      end

      describe '#post_process' do
        it 'adds post processor without key' do
          expect(endpoint.response_processor).to receive(:add_post_processor).with(nil)
          wrapper.post_process { |h| }
        end

        it 'adds post processor with key' do
          expect(endpoint.response_processor).to receive(:add_post_processor).with('count')
          wrapper.post_process('count') { |h| }
        end
      end

      describe '#post_process_each' do
        it 'adds post processor without key' do
          expect(endpoint.response_processor).to receive(:add_item_post_processor).with('list', nil)
          wrapper.post_process_each('list') { |h| }
        end

        it 'adds post processor with key' do
          expect(endpoint.response_processor).to receive(:add_item_post_processor).with('list', 'dt')
          wrapper.post_process_each('list', 'dt') { |h| }
        end
      end
    end
  end
end
