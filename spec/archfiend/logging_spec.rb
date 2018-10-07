RSpec.describe Archfiend::Logging do
  describe '.create' do
    subject { described_class.create(environment, log_directory, quiet) }

    let(:environment) { 'test' }
    let(:log_directory) { '/tmp' }
    let(:file_logger) { instance_double(Logger, :formatter= => true) }

    before do
      allow(Logger).to receive(:new).with("/tmp/#{environment}.log", 'daily').and_return(file_logger)
    end

    context 'when quiet is true' do
      let(:quiet) { true }

      it 'returns a MultiLogger instance with single logger' do
        expect(subject.loggers).to eq([file_logger])
      end
    end

    context 'when quiet is false' do
      let(:quiet) { false }

      context 'when environment is development' do
        let(:environment) { 'development' }
        let(:stdout_logger) { instance_double(Logger, :formatter= => true) }

        it 'returns a MultiLogger instance with two loggers' do
          expect(Logger).to receive(:new).with(STDOUT).and_return(stdout_logger)
          expect(subject.loggers).to eq([file_logger, stdout_logger])
        end
      end
    end
  end
end
