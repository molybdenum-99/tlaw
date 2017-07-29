module TLAW
  describe APIPath do
    describe '.define_method_on' do
      let(:object) {
        Class.new(described_class) {
          def self.to_code
            "def foo\nputs 'foo'\nend"
          end
        }
      }
      let(:host) { double }

      it 'sends definition to host' do
        expect(host).to receive(:module_eval)
          .with("def foo\nputs 'foo'\nend", __FILE__, 7)

        object.define_method_on(host)
      end
    end

    describe '.class_name' do
      let(:object) {
        Class.new(described_class).tap { |c| c.symbol = symbol }
      }

      subject { object.class_name }

      context 'for regular symbols' do
        let(:symbol) { :my_dear_baby_13 }

        it { is_expected.to eq 'MyDearBaby13' }
      end

      context '[]' do
        let(:symbol) { :[] }

        it { is_expected.to eq 'Element' }
      end
    end

    describe '.to_method_definition' do
      subject(:example) {
        Class.new(described_class).tap { |c|
          c.symbol = :foo
          c.param_set.add(:bar, required: true, keyword: false)
          c.param_set.add(:baz)
        }
      }

      its(:to_method_definition) { is_expected.to eq('foo(bar, baz: nil)') }
    end
  end
end
