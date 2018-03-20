module TLAW
  describe DSL do
    let(:block) { ->(*) {} }

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

      before {
        namespace.base_url = 'https://api.example.com'
        stub_const('Ns', namespace)
      }

      describe '#define' do
        let(:block) { -> {} }

        it 'calls definition API' do
          expect(wrapper).to receive(:instance_eval) { |&b| expect(b).to eq block }
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
          wrapper.description %{
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

      shared_examples 'child definition' do |klass, definer, getter|
        after {
          Ns.send(:remove_const, :Ep1)
        }

        subject { namespace.send(getter)[:ep1] }

        context 'default' do
          before {
            wrapper.send definer, :ep1
          }

          it { is_expected.to be_a Class }
          it { is_expected.to be < klass }
          its(:symbol) { is_expected.to eq :ep1 }
          its(:path) { is_expected.to eq '/ep1' }
          its(:name) { is_expected.to eq 'Ns::Ep1' }
          its(:base_url) { is_expected.to eq 'https://api.example.com/ep1' }
          its(:'param_set.parent') { is_expected.to eq namespace.param_set }
          its(:'response_processor.parent') { is_expected.to eq namespace.response_processor }
        end

        context 'calling the block' do
          before {
            wrapper.send(definer, :ep1) do
              param :foo
            end
          }

          its(:'param_set.names') { is_expected.to include(:foo) }
        end

        context 'explicit path' do
          before {
            wrapper.send definer, :ep1, '/foo/bar'
          }
          its(:path) { is_expected.to eq '/foo/bar' }
        end

        context 'params guessing from url' do
          before {
            wrapper.send definer, :ep1, '/foo/{bar}{/baz}'
          }
          its(:'param_set.names') { is_expected.to include(:bar, :baz) }
        end

        context 'update existing' do
          before {
            wrapper.send definer, :ep1, '/foo/{bar}{/baz}'
            wrapper.send definer, :ep1 do
              param :quux
            end
          }
          its(:'param_set.names') { is_expected.to include(:bar, :baz, :quux) }
        end
      end

      describe '#endpoint' do
        it_behaves_like 'child definition', Endpoint, :endpoint, :endpoints
      end

      describe '#namespace' do
        it_behaves_like 'child definition', Namespace, :namespace, :namespaces
      end

      context 'update existing: when different types' do
        before {
          wrapper.endpoint :ep1
        }

        specify { expect { wrapper.namespace :ep1 }.to raise_error(ArgumentError, /can't redefine it/) }
      end
    end

    describe DSL::EndpointWrapper do
      let(:endpoint) { Class.new(Endpoint) }
      let(:wrapper) { described_class.new(endpoint) }

      describe '#define' do
        let(:block) { -> {} }

        it 'calls definition API' do
          expect(wrapper).to receive(:instance_eval) { |&b| expect(b).to eq block }
          wrapper.define(&block)
        end
      end

      describe '#param' do
        it 'creates params' do
          expect(endpoint.param_set).to receive(:add).with(:param1, type: String, required: true)
          wrapper.param :param1, String, required: true
        end
      end

      describe '#transform' do
        it 'adds post processor without key' do
          expect(endpoint.response_processor.processors).to receive(:<<).with(DSL::Transforms::Base)
          wrapper.transform { |h| }
        end

        it 'adds post processor with key' do
          expect(endpoint.response_processor.processors).to receive(:<<).with(DSL::Transforms::Key)
          wrapper.transform('count') { |h| }
        end
      end

      describe '#transform_items' do
        it 'adds post processor without key' do
          expect(endpoint.response_processor.processors).to receive(:concat).with([DSL::Transforms::Items])
          wrapper.transform_items('list') { transform { |h| } }
        end

        it 'adds post processor with key' do
          expect(endpoint.response_processor.processors).to receive(:concat).with([DSL::Transforms::Items])
          wrapper.transform_items('list') { transform('dt') { |h| } }
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

      expect(api.some_ns.method(:some_ep).parameters).to eq [%i[key foo]]
    end
  end
end
