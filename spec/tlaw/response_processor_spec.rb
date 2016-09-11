module TLAW
  describe ResponseProcessor do
    let(:processor) { described_class.new }

    describe 'initial flattening' do
      let(:source) {
        {
          'response' => {
            'count' => 10
          },
          'list' => [
            {'weather' => {'temp' => 10}},
            {'weather' => {'temp' => 15}},
          ]
        }
      }

      subject { processor.send(:flatten, source) }

      it { is_expected.to eq(
          'response.count' => 10,
          'list' => [
            {'weather.temp' => 10},
            {'weather.temp' => 15},
          ]
      )}

    end

    describe 'processors' do
      let(:t1) { Time.parse('2016-01-05 13:30') }
      let(:t2) { Time.parse('2016-01-05 13:30') }

      let(:source) {
        {
          'count' => '10',
          'list' => [
            {'t' => t1.to_i},
            {'t' => t2.to_i}
          ],
          'dummy' => 'nothing to see here'
        }
      }

      subject { processor.send(:post_process, source) }

      context 'global' do
        before {
          processor.add_post_processor { |h|
            h['count'] = h['count'].to_i
          }
        }

        its(['count']) { is_expected.to eq 10 }
      end

      context 'one key' do
        before {
          processor.add_post_processor('count', &:to_i)
        }

        its(['count']) { is_expected.to eq 10 }

        context 'key is absent' do
          let(:source) { {} }

          it { is_expected.not_to include('count') }
        end
      end

      context 'each element of array by key' do
        before {
          processor.add_item_post_processor('list') { |h| h['t'] = Time.at(h['t']) }
        }

        it { expect(subject['list'].map{|h| h['t']}).to all be_a(Time) }
      end

      context 'each element -> key' do
        before {
          processor.add_item_post_processor('list', 't') { |v| Time.at(v) }
        }

        it { expect(subject['list'].map{|h| h['t']}).to all be_a(Time) }

        context 'key is absent' do
          let(:source) { {'list' => [{'i' => 1}, {'i' => 2}]} }

          it { expect(subject['list'].map{|h| h.has_key?('t')}).to all be_falsey  }
        end
      end

      context 'removing unnecessary' do
        before {
          processor.add_post_processor('dummy') { nil }
        }

        it { is_expected.not_to include('dummy') }
      end

      context 'reflattening' do
        before {
          processor.add_post_processor('count') { {'total' => 100, 'current' => 10} }
        }

        it { is_expected.not_to include('count') }
        it { is_expected.to include('count.total' => 100, 'count.current' => 10) }
      end
    end

    describe 'converting to data tables' do
      let(:source) {
        {
          'count' => 2,
          'list' => [
            {'i' => 1, 'val' => 'xxx'},
            {'i' => 2, 'val' => 'yyy'},
          ]
        }
      }

      subject { processor.send(:datablize, source)['list'] }

      it { is_expected.to be_a DataTable }
      its(:keys) { is_expected.to eq %w[i val] }
    end

    describe 'all at once' do
    end
  end
end
