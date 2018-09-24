module TLAW
  describe API do
    let(:api_class) {
      Class.new(API) do
        define do
          base 'http://api.example.com'

          param :api_key, required: true

          endpoint :some_ep do
            param :foo
          end

          namespace :some_ns do
            endpoint :other_ep
          end
        end
      end
    }

    context '.define' do
      let(:block) { -> {} }
      let(:wrapper) { instance_double('TLAW::DSL::APIWrapper', define: nil) }

      subject { api_class.define(&block) }

      its_block do
        is_expected.to send_message(DSL::APIWrapper, :new).with(api_class).returning(wrapper)
          .and send_message(wrapper, :define)
      end
    end

    context 'documentation' do
      let(:api) { api_class.new(api_key: '123') }

      before { allow(api_class).to receive(:name).and_return('Dummy') }

      context '.inspect' do
        subject { api_class.inspect }

        it { is_expected.to eq 'Dummy(call-sequence: Dummy.new(api_key:); namespaces: some_ns; endpoints: some_ep; docs: .describe)' }
      end

      context '#inspect' do
        subject { api.inspect }

        it { is_expected.to eq '#<Dummy.new(api_key: "123") namespaces: some_ns; endpoints: some_ep; docs: .describe>' }
      end
    end
  end
end
