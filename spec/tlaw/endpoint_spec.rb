module TLAW
  describe Endpoint do
    let(:url_template) { 'https://api.example.com' }
    let(:endpoint_class) { Class.new(described_class).tap { |c| c.base_url = url_template } }
    let(:endpoint) { endpoint_class.new }

    context '.param_set' do
      subject { endpoint_class }

      its(:param_set) { is_expected.to be_a Params::Set }
    end

    describe '#construct_url' do
      let(:params) { {} }

      subject(:url) { endpoint.__send__(:construct_url, **params) }

      context 'no params' do
        it { is_expected.to eq 'https://api.example.com/' }
      end

      context 'only query params' do
        before {
          endpoint_class.param_set.add(:q)
          endpoint_class.param_set.add(:pagesize, type: :to_i, format: ->(v) { v * 10 })
        }
        let(:params) { {q: 'Kharkiv oblast', pagesize: 10} }

        it { is_expected.to eq 'https://api.example.com/?q=Kharkiv%20oblast&pagesize=100' }
      end

      context 'path & query params' do
        before {
          endpoint_class.param_set.add(:q)
          endpoint_class.param_set.add(:pagesize, type: :to_i, format: ->(v) { v * 10 })
        }
        let(:params) { {q: 'Kharkiv', pagesize: 10} }

        let(:url_template) { 'https://api.example.com{/q}' }

        it { is_expected.to eq 'https://api.example.com/Kharkiv?pagesize=100' }
      end

      context 'path with ?' do
        before {
          endpoint_class.param_set.add(:q)
          endpoint_class.param_set.add(:pagesize, type: :to_i, format: ->(v) { v * 10 })
        }
        let(:params) { {q: 'Kharkiv', pagesize: 10} }

        let(:url_template) { 'https://api.example.com?q={q}' }

        it { is_expected.to eq 'https://api.example.com/?q=Kharkiv&pagesize=100' }
      end

      context 'parent-defined params'
    end

    describe '#call' do
      before {
        endpoint_class.param_set.add(:q)
        endpoint_class.response_processor.add_post_processor('response.message', &:downcase)
      }

      let(:deep_hash) {
        {
          response: {status: 200, message: 'OK'},
          data: {field1: 'foo', field2: {bar: 1}}
        }
      }

      it 'calls web with params provided' do
        expect { endpoint.call(q: 'Why') }
          .to get_webmock('https://api.example.com?q=Why')
          .and_return({test: 'me'}.to_json)
      end

      context 'parent params' do
        let(:parent_param_set) {
          Params::Set.new.tap { |ps| ps.add(:api_key) }
        }
        let(:endpoint) { endpoint_class.new(api_key: 'foo') }

        before {
          endpoint_class.param_set.parent = parent_param_set
        }

        it 'calls web with params provided' do
          expect { endpoint.call(q: 'Why') }
            .to get_webmock('https://api.example.com?api_key=foo&q=Why')
            .and_return({test: 'me'}.to_json)
        end
      end

      it 'parses response & flatterns it' do
        stub_request(:get, 'https://api.example.com?q=Why')
          .to_return(body: deep_hash.to_json)

        expect(endpoint.call(q: 'Why'))
          .to eq(
            'response.status' => 200,
            'response.message' => 'ok',
            'data.field1' => 'foo',
            'data.field2.bar' => 1
          )
      end

      context 'errors' do
        context 'just code' do
          before {
            stub_request(:get, 'https://api.example.com?q=Why')
              .to_return(status: 404)
          }

          specify {
            expect { endpoint.call(q: 'Why') }
              .to raise_error(API::Error, 'HTTP 404 at https://api.example.com/?q=Why')
          }
        end
        context 'code + json message'
        context 'code + text'
        context 'code + html'

        context 'exception while processing' do
          before {
            stub_request(:get, 'https://api.example.com?q=Why')
              .to_return { fail JSON::ParserError, 'Unparseable!' }
          }

          specify {
            expect { endpoint.call(q: 'Why') }
              .to raise_error(API::Error, 'JSON::ParserError at https://api.example.com/?q=Why: Unparseable!')
          }
        end
      end
    end

    describe '#to_code' do
      before {
        endpoint_class.symbol = :ep

        endpoint_class.param_set.add :kv1
        endpoint_class.param_set.add :kv2, required: true
        endpoint_class.param_set.add :kv3, default: 14

        endpoint_class.param_set.add :arg1, keyword: false
        endpoint_class.param_set.add :arg2, keyword: false, default: 'foo'
        endpoint_class.param_set.add :arg3, keyword: false, required: true
      }

      subject { endpoint_class.to_code }

      it { is_expected
        .to  include('def ep(arg3, arg1=nil, arg2="foo", kv2:, kv1: nil, kv3: 14)')
        .and include('.call(kv1: kv1, kv2: kv2, kv3: kv3, arg1: arg1, arg2: arg2, arg3: arg3)')
      }
    end

    context 'documentation' do
      before {
        endpoint_class.symbol = :ep
        endpoint_class.description = "This is cool endpoint!\nIt works."

        endpoint_class.param_set.add :kv1, type: Time
        endpoint_class.param_set.add :kv2, type: :to_i, required: true

        endpoint_class.param_set.add :arg1, keyword: false
        endpoint_class.param_set.add :arg3, type: :to_time, keyword: false, required: true

        allow(endpoint_class).to receive(:name).and_return('SomeEndpoint')
      }

      describe '#inspect' do
        subject { endpoint.inspect }

        it { is_expected.to eq 'SomeEndpoint(call-sequence: ep(arg3, arg1=nil, kv2:, kv1: nil); docs: .describe)' }
      end

      describe '#describe' do
        subject { endpoint.describe.to_s }

        it { is_expected.to eq(%{
          |.ep(arg3, arg1=nil, kv2:, kv1: nil)
          |  This is cool endpoint!
          |  It works.
          |
          |  @param arg3 [#to_time]
          |  @param arg1
          |  @param kv2 [#to_i]
          |  @param kv1 [Time]
        }.unindent)}
      end
    end
  end
end
