module TLAW
  describe API do
    context '.define' do
      let(:block) { ->{} }
      let(:wrapper) { instance_double('TLAW::DSL::APIWrapper') }
      let(:api_class) { Class.new(described_class) }

      it 'works' do
        expect(DSL::APIWrapper).to receive(:new).with(api_class).and_return(wrapper)
        expect(wrapper).to receive(:define)
        api_class.define(&block)
      end
    end

    xcontext 'documentation' do
      let(:api_class) {
        Class.new(API) do
          define do
            base 'http://api.example.com'

            param :api_key, required: true

            endpoint :some_ep do
              param :foo
            end

            namespace :some_ns do
            end
          end
        end
      }
      let(:api) { api_class.new(api_key: '123') }

      before { allow(api_class).to receive(:name).and_return('Dummy') }

      context '.inspect' do
        subject { api_class.inspect }

        it { is_expected.to eq '#<Dummy create: Dummy.new(api_key:), docs: Dummy.describe>' }
      end

      context '#inspect' do
        subject { api.inspect }

        it { is_expected.to eq '#<Dummy(api_key: "123") namespaces: some_ns; endpoints: some_ep; docs: .describe>' }
      end

    end
  end
end
