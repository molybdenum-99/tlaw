# frozen_string_literal: true

RSpec.describe TLAW::APIPath do
  let(:parent_cls) {
    class_double(
      'TLAW::ApiPath',
      parent: nil,
      url_template: 'http://example.com/{x}',
      full_param_defs: [param(:x), param(:y)]
    )
  }

  let(:parent) { instance_double('TLAW::APIPath', prepared_params: {x: 'xxx'}) }
  let(:cls) {
    described_class.define(
      symbol: :bar,
      path: '/bar',
      param_defs: [
        param(:a, required: true),
        param(:b, type: Integer, field: :bb),
        param(:c, format: ->(t) { t.strftime('%Y-%m-%d') }),
        param(:d, type: {true => 't', false => 'f'})
      ]
    ).tap { |res| res.parent = parent_cls }
  }

  describe '.define' do
    subject(:cls) { described_class.define(**args) }

    let(:args) {
      {
        symbol: :foo,
        path: '/bar',
        description: 'Test.',
        docs_link: 'http://google.com',
        param_defs: [
          param(:a),
          param(:b, keyword: false, required: true)
        ]
      }
    }

    it { is_expected.to be_a(Class).and be.<(described_class) }
    # its(:definition) { is_expected.to eq args }

    it {
      is_expected.to have_attributes(
        symbol: :foo,
        path: '/bar',
        # description: 'Test.', -- hm...
        docs_link: 'http://google.com',
        param_defs: be_an(Array).and(have_attributes(size: 2))
      )
    }

    context 'without parent' do
      it {
        expect { cls.url_template }
          .to raise_error RuntimeError, "Orphan path /bar, can't determine full URL"
      }
    end

    context 'with parent' do
      before { cls.parent = parent_cls }
      it {
        is_expected.to have_attributes(
          url_template: 'http://example.com/{x}/bar',
          full_param_defs: be_an(Array).and(have_attributes(size: 4))
        )
      }
      its(:parents) { are_expected.to eq [parent_cls] }
    end
  end

  describe '#initialize' do
    subject(:path) { cls.new(parent, a: 5) }

    its(:parent) { is_expected.to eq parent }
  end

  describe '#prepared_params' do
    subject { ->(params) { cls.new(parent, **params).prepared_params } }

    its_call(a: 1, b: 2, c: Time.parse('2017-05-01'), d: true) {
      is_expected.to ret(a: '1', bb: '2', c: '2017-05-01', d: 't', x: 'xxx')
    }
    its_call(a: 1, b: nil) {
      is_expected.to ret(a: '1', x: 'xxx')
    }

    its_call(a: [1, 2, 3]) {
      is_expected.to ret(a: '1,2,3', x: 'xxx')
    }

    its_call(b: 2) {
      is_expected.to raise_error(ArgumentError, 'Missing arguments: a')
    }
    its_call(a: 1, e: 2) {
      is_expected.to raise_error(ArgumentError, 'Unknown arguments: e')
    }
    its_call(a: 1, b: 'test') {
      is_expected.to raise_error(TypeError, 'b: expected instance of Integer, got "test"')
    }
  end
end
