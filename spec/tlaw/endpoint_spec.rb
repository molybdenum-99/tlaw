module TLAW
  describe Endpoint do
    describe '.add_param' do
    end

    let(:url_template) { 'https://api.example.com' }
    let(:api) { instance_double('TLAW::API') }
    let(:endpoint_class) { Class.new(Endpoint).tap { |c| c.url = url_template } }
    let(:endpoint) { endpoint_class.new(api) }

    describe '#construct_url' do
      let(:params) { {} }

      subject(:url) { endpoint.__send__(:construct_url, params) }

      context 'no params' do
        it { is_expected.to eq 'https://api.example.com' }
      end

      context 'only query params' do
        before {
          endpoint_class.add_param(:q)
          endpoint_class.add_param(:pagesize, type: :to_i, format: ->(v) { v*10 })
        }
        let(:params) { {q: 'Kharkiv oblast', pagesize: 10, page: 5} }

        it { is_expected.to eq 'https://api.example.com?q=Kharkiv%20oblast&pagesize=100' }
      end

      context 'path & query params' do
        before {
          endpoint_class.add_param(:q)
          endpoint_class.add_param(:pagesize, type: :to_i, format: ->(v) { v*10 })
        }
        let(:params) { {q: 'Kharkiv', pagesize: 10, page: 5} }

        let(:url_template) { 'https://api.example.com{/q}' }

        it { is_expected.to eq 'https://api.example.com/Kharkiv?pagesize=100' }
      end

      context 'path with ?' do
        before {
          endpoint_class.add_param(:q)
          endpoint_class.add_param(:pagesize, type: :to_i, format: ->(v) { v*10 })
        }
        let(:params) { {q: 'Kharkiv', pagesize: 10, page: 5} }

        let(:url_template) { 'https://api.example.com?q={q}' }

        it { is_expected.to eq 'https://api.example.com?q=Kharkiv&pagesize=100' }
      end
    end

    describe '#call' do
      before {
        endpoint_class.add_param(:q)
        endpoint_class.response_processor.add_post_processor('response.message', &:downcase)
      }

      it 'calls web with params provided' do
        expect { endpoint.call(q: 'Why') }
          .to get_webmock('https://api.example.com?q=Why')
          .and_return({test: 'me'}.to_json)
      end

      let(:deep_hash) {
        {
          response: {status: 200, message: 'OK'},
          data: {field1: 'foo', field2: {bar: 1}}
        }
      }

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
              .to raise_error(API::Error, 'HTTP 404 at https://api.example.com?q=Why')
          }
        end
        context 'code + json message'
        context 'code + text'
        context 'code + html'

        context 'exception while processing' do
          before {
            stub_request(:get, 'https://api.example.com?q=Why')
              .to_return { raise JSON::ParserError, 'Unparseable!' }
          }

          specify {
            expect { endpoint.call(q: 'Why') }
              .to raise_error(API::Error, 'JSON::ParserError at https://api.example.com?q=Why: Unparseable!')
          }
        end
      end
    end

    describe '#generated_definition' do
      before {
        endpoint_class.endpoint_name = :ep

        endpoint_class.add_param :kv1
        endpoint_class.add_param :kv2, required: true
        endpoint_class.add_param :kv3, default: 14

        endpoint_class.add_param :arg1, keyword_argument: false
        endpoint_class.add_param :arg2, keyword_argument: false, default: 'foo'
        endpoint_class.add_param :arg3, keyword_argument: false, required: true

        endpoint_class.add_param :cm1, common: true
      }

      subject { endpoint_class.generate_definition }

      it { is_expected
        .to  include('def ep(arg3, arg1=nil, arg2="foo", kv2:, kv1: nil, kv3: 14)')
        .and include('param = initial_param.merge(kv1: kv1, kv2: kv2, kv3: kv3, arg1: arg1, arg2: arg2, arg3: arg3)')
        .and include('endpoints[:ep].call(**param)')
      }
    end

    context 'documentation' do
      before {
        endpoint_class.endpoint_name = :ep

        endpoint_class.add_param :kv1
        endpoint_class.add_param :kv2, required: true

        endpoint_class.add_param :arg1, keyword_argument: false
        endpoint_class.add_param :arg3, keyword_argument: false, required: true

        allow(endpoint_class).to receive(:name).and_return('SomeEndpoint')
      }

      describe '#inspect' do
        subject { endpoint.inspect }

        it { is_expected.to eq '#<SomeEndpoint: call-sequence (arg3, arg1=nil, kv2:, kv1: nil); docs: .describe>' }
      end
    end
  end
end
