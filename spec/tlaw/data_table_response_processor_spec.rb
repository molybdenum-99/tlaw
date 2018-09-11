module TLAW
  module Processors
    describe DataTableResponseProcessor do
      let(:processor) { described_class.new }
      let(:endpoint) { Class.new(Endpoint).tap { |endpoint| endpoint.response_processor = processor } }
      let(:wrapper) { DSL::EndpointWrapper.new(endpoint) }

      describe 'initial flattening' do
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

        subject { processor.send(:flatten, source) }

        it { is_expected.to eq(
          'response.count' => 10,
          'list' => [
            {'weather.temp' => 10},
            {'weather.temp' => 15}
          ]
        )
        }
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

        let(:json_response) do
          Faraday::Response.new(
            status: 200,
            method: :get,
            body: JSON.dump(source),
            response_headers: {
              'Content-Type' => 'application/json'
            }
          )
        end

        subject(:response) { processor.send(:call, json_response) }

        context 'global' do
          before {
            wrapper.transform { |h|
              h['count'] = h['count'].to_i
            }
          }

          its(['count']) { is_expected.to eq 10 }
        end

        context 'one key' do
          before {
            wrapper.transform('count', &:to_i)
          }

          its(['count']) { is_expected.to eq 10 }

          context 'key is absent' do
            let(:source) { {} }

            it { is_expected.not_to include('count') }
          end
        end

        context 'each element' do
          subject { response['list'] }

          context 'by key' do
            before {
              wrapper.transform_item('list') { |h| h['t'] = Time.at(h['t']) }
            }

            its_map(['t']) { are_expected.to all be_a(Time) }
          end

          context 'element -> key' do
            before {
              wrapper.transform_item('list', 't') { |v| Time.at(v) }
            }

            its_map(['t']) { are_expected.to all be_a(Time) }

            context 'key is absent' do
              let(:source) { {'list' => [{'i' => 1}, {'i' => 2}]} }

              it { is_expected.to all not_have_key('t') }
            end
          end
        end

        context 'removing unnecessary' do
          before {
            wrapper.transform('dummy') { nil }
          }

          it { is_expected.not_to include('dummy') }
        end

        context 'reflattening' do
          before {
            wrapper.transform('count') { {'total' => 100, 'current' => 10} }
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
              {'i' => 2, 'val' => 'yyy'}
            ]
          }
        }

        subject { processor.send(:datablize, source)['list'] }

        it { is_expected.to be_a DataTable }
        its(:keys) { is_expected.to eq %w[i val] }
      end

      describe 'all at once'
    end
  end
end
