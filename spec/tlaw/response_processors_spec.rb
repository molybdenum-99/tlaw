RSpec.describe TLAW::ResponseProcessors do
  # TODO: more thorough tests, these are obviously ad-hoc
  describe 'Generators.transform_nested' do
    context 'without nested key' do
      subject { described_class::Generators.transform_nested(:c) { |h| h[:d] = 5 } }

      its_call(a: 1, b: 2, c: [{a: 3}, {b: 4}]) {
        is_expected.to ret(a: 1, b: 2, c: [{a: 3, d: 5}, {b: 4, d: 5}])
      }
    end

    context 'with nested key' do
      subject { described_class::Generators.transform_nested(:c, :a, &:to_s) }

      its_call(a: 1, b: 2, c: [{a: 3}, {b: 4}]) {
        is_expected.to ret(a: 1, b: 2, c: [{a: '3'}, {b: 4}])
      }
    end
  end

  describe '.flatten' do
    let(:source) {
      {
        'response' => {
          'count' => 10
        },
        'list' => [
          {'weather' => {'temp' => 10}},
          {'weather' => {'temp' => 15}}
        ]
      }
    }

    subject { described_class.flatten(source) }

    it {
      is_expected.to eq(
        'response.count' => 10,
        'list' => [
          {'weather.temp' => 10},
          {'weather.temp' => 15}
        ]
      )
    }
  end

  describe '.datablize' do
    let(:source) {
      {
        'count' => 2,
        'list' => [
          {'i' => 1, 'val' => 'xxx'},
          {'i' => 2, 'val' => 'yyy'}
        ]
      }
    }

    subject { described_class.datablize(source)['list'] }

    it { is_expected.to be_a TLAW::DataTable }
    its(:keys) { are_expected.to eq %w[i val] }
  end
end