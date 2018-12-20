# frozen_string_literal: true

RSpec.describe TLAW::Namespace do
  let(:cls) {
    described_class.define(
      symbol: :ns,
      path: '/ns',
      children: [ep, ns]
    ).tap { |c| c.parent = parent_cls }
  }
  let(:parent_cls) { class_double('TLAW::APIPath', url_template: 'http://foo/bar') }
  let(:ns) {
    described_class.define(symbol: :ns1, path: '/ns1', param_defs: [param(:x)])
  }
  let(:ep) {
    TLAW::Endpoint.define(symbol: :ep1, path: '/ep1', param_defs: [param(:x)])
  }

  describe '.define' do
    subject(:cls) {
      described_class.define(
        symbol: :ns,
        path: '/ns',
        param_defs: [param(:a), param(:b)],
        children: [
          TLAW::Endpoint.define(symbol: :ep1, path: '/ep1'),
          described_class.define(symbol: :ns1, path: '/ns1')
        ]
      )
    }

    its(:children) {
      are_expected
        .to match [
          be.<(TLAW::Endpoint).and(have_attributes(symbol: :ep1, parent: cls)),
          be.<(described_class).and(have_attributes(symbol: :ns1, parent: cls))
        ]
    }

    before {
      allow(cls).to receive(:name).and_return('Namespace')
    }

    its(:inspect) {
      is_expected.to eq 'Namespace(call-sequence: ns(a: nil, b: nil); namespaces: ns1; endpoints: ep1; docs: .describe)'
    }
    its(:describe) { is_expected.to be_a String }
  end

  describe '.child' do
    subject { cls.method(:child) }

    its_call(:ep1, restrict_to: TLAW::Endpoint) { is_expected.to ret be < TLAW::Endpoint }
    its_call(:ep1, restrict_to: described_class) {
      is_expected.to raise_error ArgumentError, 'Unregistered namespace: ep1'
    }
    its_call(:ns1, restrict_to: described_class) { is_expected.to ret be < described_class }
    its_call(:ns1) { is_expected.to ret be < described_class }
    its_call(:ns2) {
      is_expected.to raise_error ArgumentError, 'Unregistered path: ns2'
    }
  end

  describe '.endpoint' do
    subject { cls.method(:endpoint) }

    its_call(:ep1) { is_expected.to ret be < TLAW::Endpoint }
    its_call(:ns1) {
      is_expected.to raise_error ArgumentError, 'Unregistered endpoint: ns1'
    }
    its_call(:ns2) {
      is_expected.to raise_error ArgumentError, 'Unregistered endpoint: ns2'
    }
  end

  describe '.namespace' do
    subject { cls.method(:namespace) }

    its_call(:ns1) { is_expected.to ret be < described_class }
    its_call(:ep1) {
      is_expected.to raise_error ArgumentError, 'Unregistered namespace: ep1'
    }
    its_call(:ns2) {
      is_expected.to raise_error ArgumentError, 'Unregistered namespace: ns2'
    }
  end

  describe '.traverse' do
    let(:namespace_class) {
      TLAW::DSL::NamespaceBuilder.new(symbol: :root) do
        endpoint :endpoint
        namespace :child do
          endpoint :child_endpoint
          namespace :grand_child
        end
      end.finalize
    }

    subject { ->(*args) { namespace_class.traverse(*args).to_a } }

    it { is_expected.to ret contain_exactly(
      have_attributes(symbol: :endpoint),
      have_attributes(symbol: :child),
      have_attributes(symbol: :child_endpoint),
      have_attributes(symbol: :grand_child)
    )
    }

    its_call(:endpoints) { is_expected.to ret contain_exactly(
      have_attributes(symbol: :endpoint),
      have_attributes(symbol: :child_endpoint)
    )
    }

    its_call(:namespaces) { is_expected.to ret contain_exactly(
      have_attributes(symbol: :child),
      have_attributes(symbol: :grand_child)
    )
    }

    its_call(:garbage) { is_expected.to raise_error KeyError }
  end

  describe '#child' do
    let(:obj) { cls.new(nil) }

    subject { obj.method(:child) }

    its_call(:ep1, TLAW::Endpoint, x: 1) { is_expected.to ret be_a(ep).and have_attributes(params: {x: 1}) }
    its_call(:ep1, described_class, x: 1) { is_expected.to raise_error ArgumentError, 'Unregistered namespace: ep1' }
    its_call(:ns1, described_class, x: 1) { is_expected.to ret be_a(ns).and have_attributes(params: {x: 1}) }
  end

  context 'formatting' do
    before {
      allow(cls).to receive(:name).and_return('Namespace')
    }

    subject(:obj) { cls.new(nil, a: 1, b: 5) }

    its(:inspect) {
      is_expected.to eq '#<Namespace(a: 1, b: 5); namespaces: ns1; endpoints: ep1; docs: .describe>'
    }
    its(:describe) { is_expected.to eq cls.describe }
  end
end
