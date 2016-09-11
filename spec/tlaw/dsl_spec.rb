module TLAW
  describe DSL do
    let(:block) { ->{} }

    describe DSL::APIWrapper do
      let!(:api) { Class.new(API) }
      let(:wrapper) { described_class.new(api) }

      describe '#base' do
        let(:url) { Faker::Internet.url }

        it 'sets base url' do
          expect(api).to receive(:base_url=).with(url)
          wrapper.base url
        end
      end
    end

    describe DSL::NamespaceWrapper do
      let!(:namespace) { Class.new(Namespace) }
      let!(:wrapper) { described_class.new(namespace) }

      describe '#define' do
        let(:block) { ->{} }
        it 'calls definition API' do
          expect(wrapper).to receive(:instance_eval){|&b| expect(b).to eq block }
          wrapper.define(&block)
        end
      end

      describe '#description' do
        it 'writes description to object' do
          expect(namespace).to receive(:description=).with('It is cool')
          wrapper.description 'It is cool'
        end

        it 'deindents description' do
          expect(namespace).to receive(:description=)
            .with("It is pretty cool.\nAnd concise, see.\n\nMultispace!")
          wrapper.description %Q{
            It is pretty cool.
            And concise, see.

            Multispace!
          }
        end
      end

      describe '#param' do
        it 'adds parameter' do
          expect(namespace.param_set).to receive(:add)
            .with(:param1, type: String, required: true)
          wrapper.param :param1, String, required: true
        end
      end

      describe '#endpoint' do
        let(:endpoint) { Class.new(TLAW::Endpoint) }
        let(:endpoint_wrapper) { instance_double('TLAW::DSL::EndpointWrapper') }

        it 'creates endpoint and adds it' do
          expect(Class).to receive(:new)
            .with(Endpoint).and_return(endpoint)

          expect(endpoint).to receive(:path=).with('/ep1').and_call_original
          expect(endpoint).to receive(:symbol=).with(:ep1)

          expect(DSL::EndpointWrapper).to receive(:new)
            .with(endpoint).and_return(endpoint_wrapper)

          expect(endpoint_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(namespace).to receive(:add_child).with(endpoint)

          wrapper.endpoint :ep1, &block
        end

        it 'allows explicit path' do
          expect(Class).to receive(:new)
            .with(Endpoint).and_return(endpoint)

          expect(endpoint).to receive(:path=).with('/ns1/ns2/ep1').and_call_original
          expect(endpoint).to receive(:symbol=).with(:ep1)

          expect(DSL::EndpointWrapper).to receive(:new)
            .with(endpoint)
            .and_return(endpoint_wrapper)

          expect(endpoint_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(namespace).to receive(:add_child).with(endpoint)

          wrapper.endpoint :ep1, '/ns1/ns2/ep1', &block
        end

        it 'guesses params from url' do
          expect(Class).to receive(:new)
            .with(Endpoint).and_return(endpoint)

          expect(endpoint).to receive(:path=).with('/ns1/ns2/{city}').and_call_original
          expect(endpoint).to receive(:symbol=).with(:ep1)
          expect(endpoint.param_set).to receive(:add).with(:city, keyword: false)

          expect(DSL::EndpointWrapper).to receive(:new)
            .with(endpoint)
            .and_return(endpoint_wrapper)

          expect(endpoint_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(namespace).to receive(:add_child).with(endpoint)

          wrapper.endpoint :ep1, '/ns1/ns2/{city}', &block
        end
      end

      describe '#namespace' do
        let(:child) { Class.new(Namespace) }
        let(:namespace_wrapper) { instance_double('TLAW::DSL::NamespaceWrapper') }

        before {
          namespace.base_url = 'https://api.example.com'
        }

        it 'creates namespace and adds it' do
          expect(Class).to receive(:new)
            .with(Namespace).and_return(child)

          expect(child).to receive(:path=).with('/ns1').and_call_original
          expect(child).to receive(:symbol=).with(:ns1)

          expect(DSL::NamespaceWrapper).to receive(:new)
            .with(child)
            .and_return(namespace_wrapper)

          expect(namespace_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(namespace).to receive(:add_child).with(child)

          wrapper.namespace :ns1, &block
        end

        it 'allows explicit path' do
          expect(Class).to receive(:new)
            .with(Namespace).and_return(child)

          expect(child).to receive(:path=).with('/ns1/ns2').and_call_original
          expect(child).to receive(:symbol=).with(:ns1)

          expect(DSL::NamespaceWrapper).to receive(:new)
            .with(child)
            .and_return(namespace_wrapper)

          expect(namespace_wrapper).to receive(:define){|&b| expect(b).to eq block }

          expect(namespace).to receive(:add_child).with(child)

          wrapper.namespace :ns1, '/ns1/ns2', &block
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
          expect(endpoint.param_set).to receive(:add).with(:param1, type: String, required: true)
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
          expect(endpoint.response_processor)
            .to receive(:add_item_post_processor)
            .with('list', nil)
          wrapper.post_process_items('list') { post_process { |h|  } }
        end

        it 'adds post processor with key' do
          expect(endpoint.response_processor)
            .to receive(:add_item_post_processor)
            .with('list', 'dt')
          wrapper.post_process_items('list') { post_process('dt') { |h| } }
        end
      end
    end
  end

  describe 'all at once' do
    let(:api_class) {
      Class.new(API) {
        define {
          base 'http://api.example.com'
          namespace :some_ns do
            endpoint :some_ep do
              param :foo
            end
          end
        }
      }
    }

    let(:api) { api_class.new }

    it 'produces reasonable outcome' do
      expect(api.some_ns.endpoints[:some_ep].base_url)
        .to eq 'http://api.example.com/some_ns/some_ep'

      expect(api.some_ns.method(:some_ep).parameters).to eq [[:key, :foo]]
    end
  end
end
