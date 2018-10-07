require 'tempfile'

RSpec.describe Archfiend::Generators::Options do
  subject(:options) { described_class.new(args) }
  let(:args) { [] }

  describe '#extensions' do
    subject { options.extensions }
    context 'when settings file exists' do
      let(:tempfile) do
        Tempfile.new.tap do |t|
          t.puts '--extension test'
          t.close
        end
      end

      before do
        allow(Archfiend::Generators::Utils).to receive(:find_file).with('.archfiend').and_return(tempfile.path)
      end

      it 'uses settings from the file' do
        expect { subject }.to output(/\AReading #{tempfile.path}/).to_stdout
        expect(subject).to eq(Set.new(['test']))
      end

      context 'when passed some args' do
        let(:args) { ['--extension', 'test2'] }

        it 'merges settings from the file and command line' do
          expect { subject }.to output(/\AReading #{tempfile.path}/).to_stdout
          expect(subject).to eq(Set.new(%w[test test2]))
        end
      end
    end

    context 'when settings file does not exist' do
      before do
        allow(Archfiend::Generators::Utils).to receive(:find_file).with('.archfiend').and_return(nil)
      end

      it 'is empty' do
        expect(subject).to eq(Set.new([]))
      end

      context 'when passed args' do
        let(:args) { ['--extension', 'test'] }

        it 'takes args from command line' do
          expect { subject }.not_to output(/\AReading /).to_stdout
          expect(subject).to eq(Set.new(['test']))
        end
      end
    end
  end
end
