# frozen_string_literal: true

require 'tlaw/param'

RSpec.describe TLAW::Param do
  describe '#initialize' do
    subject { described_class.new(**args) }

    context 'with minimal args' do
      let(:args) { {name: :x} }

      it {
        is_expected.to have_attributes(
          name: :x,
          field: :x,
          required?: false,
          keyword?: true,
          description: nil,
          default: nil
        )
      }
    end

    context 'with all the args' do
      let(:args) {
        {
          name: :x,
          field: :_xx,
          required: true,
          keyword: false,
          description: 'Desc.',
          default: 5,
          # we don't check which value it gives, just that constructor don't fail
          format: :to_s.to_proc
        }
      }

      it {
        is_expected.to have_attributes(
          name: :x,
          field: :_xx,
          required?: true,
          keyword?: false,
          description: 'Desc.',
          default: 5
        )
      }
    end
  end

  describe '#call' do
    subject { ->(value, **definition) { described_class.new(**defaults, **definition).call(value) } }

    let(:defaults) { {name: :x} }

    context 'basics' do
      its_call('foo') { is_expected.to ret(x: 'foo') }
      its_call(5) { is_expected.to ret(x: '5') }
      its_call('foo', field: :bar) { is_expected.to ret(bar: 'foo') }
    end

    context 'typechecking' do
      its_call(5, type: Integer) { is_expected.to ret(x: '5') }
      its_call('5', type: Integer) {
        is_expected.to raise_error TypeError, 'x: expected instance of Integer, got "5"'
      }
      its_call(Time.parse('2018-03-01'), type: :year) {
        is_expected.to ret(x: '2018')
      }
      its_call('2018-03-01', type: :year) {
        is_expected.to raise_error TypeError, 'x: expected object responding to #year, got "2018-03-01"'
      }
    end

    context 'enum conversion' do
      its_call(true, type: {true => 'gzip', false => nil}) { is_expected.to ret(x: 'gzip') }
    end

    context 'value formatting' do
      its_call(5, format: ->(x) { -x }) { is_expected.to ret(x: '-5') }
    end
  end
end
