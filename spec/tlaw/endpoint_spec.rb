# frozen_string_literal: true

RSpec.describe TLAW::Endpoint do
  let(:parent_class) {
    class_double('TLAW::ApiPath',
                 url_template: 'http://example.com/{x}', full_param_defs: [param(:x), param(:y)])
  }
  let(:param_defs) { [param(:a), param(:b)] }

  let(:cls) {
    described_class
      .define(symbol: :ep, path: path, param_defs: param_defs)
      .tap { |cls| cls.parent = parent_class }
  }
  let(:path) { '/foo' }

  describe 'class behavior' do
    describe 'formatting' do
      subject { cls }

      before {
        allow(cls).to receive(:name).and_return('Endpoint')
      }

      its(:inspect) { is_expected.to eq 'Endpoint(call-sequence: ep(a: nil, b: nil); docs: .describe)' }
      its(:describe) { is_expected.to be_a String }
    end
  end

  describe 'object behavior' do
    let(:parent) {
      instance_double(
        'TLAW::ApiPath',
        prepared_params: parent_params,
        api: api,
        parent: nil
      )
    }
    let(:api) { instance_double('TLAW::API', request: nil) }
    let(:parent_params) { {x: 'bar', y: 'baz'} }

    subject(:endpoint) { cls.new(parent, a: 1, b: 2) }

    its(:request_params) { are_expected.to eq(y: 'baz', a: '1', b: '2') }
    its(:parents) { are_expected.to eq [parent] }

    describe '#url' do
      its(:url) { is_expected.to eq 'http://example.com/bar/foo' }

      context 'with .. in template' do
        let(:path) { '/../foo' }
        its(:url) { is_expected.to eq 'http://example.com/foo' }
      end
    end

    describe 'formatting' do
      before {
        allow(cls).to receive(:name).and_return('Endpoint')
      }

      its(:inspect) { is_expected.to eq '#<Endpoint(a: 1, b: 2); docs: .describe>' }
      its(:describe) { is_expected.to eq cls.describe }
    end

    describe '#call' do
      subject { endpoint.method(:call) }

      its_call {
        is_expected
          .to send_message(api, :request)
          .with('http://example.com/bar/foo', y: 'baz', a: '1', b: '2')
          .returning(instance_double('Faraday::Response', body: ''))
      }

      describe 'response parsing' do
        let(:cls) {
          TLAW::DSL::EndpointBuilder.new(symbol: :foo, **opts)
            .tap { |b| b.instance_eval(&definitions) }
            .finalize
            .tap { |cls| cls.parent = parent_class }
        }
        let(:endpoint) { cls.new(parent) }

        let(:opts) { {} }
        let(:definitions) { proc {} }
        let(:body) {
          {
            meta: {page: 1, per: 50},
            rows: [{a: 1, b: 2}, {a: 3, b: 4}]
          }.to_json
        }

        before {
          allow(api)
            .to receive(:request)
            .and_return(instance_double('Faraday::Response', body: body))
        }

        subject { endpoint.call }

        context 'by default' do
          it {
            is_expected.to eq(
              'meta.page' => 1,
              'meta.per' => 50,
              'rows' => TLAW::DataTable.new([{a: 1, b: 2}, {a: 3, b: 4}])
            )
          }
        end

        context 'with XML response' do
          let(:opts) { {xml: true} }
          let(:body) {
            '<foo><bar>1</bar><baz>2</baz></foo>'
          }

          it { is_expected.to eq('foo.bar' => '1', 'foo.baz' => '2') }
        end

        context 'additional processors' do
          let(:definitions) {
            proc do
              post_process { |h| h['additional'] = 5 }
              post_process('meta.per') { |p| p**2 }
              post_process_items('rows') {
                post_process { |i| i['c'] = -i['a'] }
                post_process('a', &:to_s)
              }
            end
          }

          it {
            is_expected.to eq(
              'meta.page' => 1,
              'meta.per' => 2500,
              'additional' => 5,
              'rows' => TLAW::DataTable.new([
                                              {'a' => '1', 'b' => 2, 'c' => -1},
                                              {'a' => '3', 'b' => 4, 'c' => -3}
                                            ])
            )
          }
        end
      end
    end
  end
end
