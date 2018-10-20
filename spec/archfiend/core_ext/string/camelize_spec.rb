RSpec.describe Archfiend::String::Camelize do
  context 'when included in some String class' do
    let(:new_string) { Class.new(String).tap { |kl| kl.include(described_class) } }

    def test_string(value)
      new_string.new(value)
    end

    describe '#camelize' do
      specify { expect(test_string('foo_bar').camelize).to eq('FooBar') }
      specify { expect(test_string('foo_bar/baz').camelize).to eq('FooBar::Baz') }
      specify { expect(test_string('foo_barBaz9').camelize).to eq('FooBarbaz9') }
      specify { expect(test_string('9foo').camelize).to eq('9foo') }
      specify { expect(test_string('')).to eq('') }
    end
  end
end
