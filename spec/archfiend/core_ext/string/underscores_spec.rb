RSpec.describe Archfiend::String::Underscore do
  context 'when included in some String class' do
    let(:new_string) { Class.new(String).tap { |kl| kl.include(described_class) } }

    def test_string(value)
      new_string.new(value)
    end

    describe '#underscore' do
      specify { expect(test_string('FooBar').underscore).to eq('foo_bar') }
      specify { expect(test_string('FooBar::Baz').underscore).to eq('foo_bar/baz') }
      specify { expect(test_string('FooBarbaz9').underscore).to eq('foo_barbaz9') }
      specify { expect(test_string('9foo').underscore).to eq('9foo') }
      specify { expect(test_string('')).to eq('') }
    end
  end
end
