module TLAW
  RSpec.describe DataTable do
    let(:data) {
      [
        {a: 1, b: 'a', c: Date.parse('2016-01-01')},
        {a: 2, b: 'b', c: Date.parse('2016-02-01'), d: 'dummy'},
        {a: 3, b: 'c', c: Date.parse('2016-03-01')}
      ]
    }

    subject(:table) { described_class.new(data) }

    context '#==' do
      it { is_expected.to eq described_class.new(data) }
    end

    context 'Array-ish behavior' do
      its(:size) { is_expected.to eq 3 }
      its([0]) { is_expected.to eq('a' => 1, 'b' => 'a', 'c' => Date.parse('2016-01-01'), 'd' => nil) }
      its(:to_a) { is_expected.to eq([
                                       {'a' => 1, 'b' => 'a', 'c' => Date.parse('2016-01-01'), 'd' => nil},
                                       {'a' => 2, 'b' => 'b', 'c' => Date.parse('2016-02-01'), 'd' => 'dummy'},
                                       {'a' => 3, 'b' => 'c', 'c' => Date.parse('2016-03-01'), 'd' => nil}
                                     ])
      }

      context 'Enumerable'
    end

    context 'Hash-ish behavior' do
      its(:keys) { is_expected.to eq %w[a b c d] }
      its([:a]) { is_expected.to eq [1, 2, 3] }
      its(['a']) { is_expected.to eq [1, 2, 3] }

      its(:to_h) { is_expected.to eq(
        'a' => [1, 2, 3],
        'b' => %w[a b c],
        'c' => [Date.parse('2016-01-01'), Date.parse('2016-02-01'), Date.parse('2016-03-01')],
        'd' => [nil, 'dummy', nil]
      )
      }

      context '#columns(a, b)' do
        subject { table.columns(:a, :b) }

        it { is_expected.to eq described_class.new(
          [
            {a: 1, b: 'a'},
            {a: 2, b: 'b'},
            {a: 3, b: 'c'}
          ]
        )
        }
      end
    end

    context '#inspect' do
      its(:inspect) { is_expected.to eq '#<TLAW::DataTable[a, b, c, d] x 3>' }
    end
  end
end
