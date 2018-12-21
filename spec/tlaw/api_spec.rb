# frozen_string_literal: true

RSpec.describe TLAW::API do
  let(:cls) {
    Class.new(described_class).tap { |cls| cls.setup(base_url: 'http://foo/{bar}') }
  }

  describe '.define' do
    subject(:cls) { Class.new(described_class) }

    before {
      cls.define do
        base 'http://foo/bar'
        endpoint :a
        namespace :b
      end
    }
    its(:url_template) { is_expected.to eq 'http://foo/bar' }
    its(:endpoints) { is_expected.to contain_exactly(be.<(TLAW::Endpoint).and(have_attributes(symbol: :a))) }
    its(:namespaces) { is_expected.to contain_exactly(be.<(TLAW::Namespace).and(have_attributes(symbol: :b))) }
  end

  describe '.setup' do
    context 'with keywords' do
      subject(:cls) {
        Class.new(described_class)
      }

      before {
        cls.setup(base_url: 'http://foo/{bar}', param_defs: [param(:x)])
        allow(cls).to receive(:name).and_return('MyAPI')
      }
      it {
        is_expected.to have_attributes(
          url_template: 'http://foo/{bar}',
          symbol: nil,
          path: ''
        )
      }
      its(:inspect) { is_expected.to eq 'MyAPI(call-sequence: MyAPI.new(x: nil); docs: .describe)' }
    end
  end

  describe '#initialize' do
    it {
      expect { |b| cls.new(&b) }.to yield_with_args(instance_of(Faraday::Connection))
    }
  end

  describe '#request' do
    let(:api) { cls.new }

    subject { api.request('http://foo/bar?x=1', y: 2) }

    its_block {
      is_expected.to get_webmock('http://foo/bar?x=1&y=2').and_return('{}')
    }

    context 'on error' do
      before {
        stub_request(:get, /.*/).to_return(status: 404, body: 'unparseable error')
      }

      its_block {
        is_expected.to raise_error TLAW::API::Error, 'HTTP 404 at http://foo/bar?x=1&y=2: unparseable error'
      }
    end

    context 'on error with extractable message' do
      before {
        stub_request(:get, /.*/).to_return(status: 404, body: {error: 'SNAFU'}.to_json)
      }

      its_block {
        is_expected.to raise_error TLAW::API::Error, 'HTTP 404 at http://foo/bar?x=1&y=2: SNAFU'
      }
    end
  end
end
