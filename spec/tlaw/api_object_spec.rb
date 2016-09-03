module TLAW
  describe APIObject do
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
  end
end
