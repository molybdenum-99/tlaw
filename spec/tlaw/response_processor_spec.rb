module TLAW
  describe ResponseProcessor do
    let(:processor) { Class.new(described_class) }
    let(:processor_instance) { processor.new }

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

      subject { processor_instance.flatten(source) }

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

      subject { processor_instance.post_process(source) }

      context 'global' do
        before {
          processor.post_process { |h|
            h['count'] = h['count'].to_i
          }
        }

        its(['count']) { is_expected.to eq 10 }
      end

      context 'one key' do
        before {
          processor.post_process('count', &:to_i)
        }

        its(['count']) { is_expected.to eq 10 }
      end

      context 'each element of array by key' do
        before {
          processor.post_process_each('list') { |h| h['t'] = Time.at(h['t']) }
        }

        it { expect(subject['list'].map{|h| h['t']}).to all be_a(Time) }
      end

      context 'each element -> key' do
        before {
          processor.post_process_each('list', 't') { |v| Time.at(v) }
        }

        it { expect(subject['list'].map{|h| h['t']}).to all be_a(Time) }
      end

      context 'removing unnecessary' do
        before {
          processor.post_process('dummy') { nil }
        }

        it { is_expected.not_to include('dummy') }
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

      subject { processor_instance.datablize(source)['list'] }

      it { is_expected.to be_a DataTable }
      its(:keys) { is_expected.to eq %w[i val] }
    end

    describe 'all at once' do
    end
  end
end
