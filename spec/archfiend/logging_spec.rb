RSpec.describe Archfiend::Logging do
  let(:settings) { instance_double('Settings', logger: logger_settings) }
  let(:logger_settings) { {} }

  before { stub_const('Settings', settings) }

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

  describe '.file_logger' do
    subject { described_class.__send__(:file_logger, environment, log_directory) }

    let(:environment) { 'development' }
    let(:log_directory) { Dir.mktmpdir }
    let(:formatter) { subject.formatter }

    after { FileUtils.remove_entry(log_directory) }

    context 'when there are formatter settings' do
      let(:logger_settings) { {formatter: {file: 'DefaultFormatter'}} }

      it 'uses setting' do
        expect(formatter).to be_a(Archfiend::Logging::DefaultFormatter)
      end
    end

    context 'when there are no formatter settings' do
      it 'uses the default value' do
        expect(formatter).to be_a(Archfiend::Logging::JSONFormatter)
      end
    end
  end

  describe '.stdio_logger' do
    subject { described_class.__send__(:stdio_logger) }
    let(:formatter) { subject.formatter }

    context 'when there are formatter settings' do
      let(:logger_settings) { {formatter: {stdout: 'JSONFormatter'}} }

      it 'uses setting' do
        expect(formatter).to be_a(Archfiend::Logging::JSONFormatter)
      end
    end

    context 'when there are no formatter settings' do
      it 'uses the default value' do
        expect(formatter).to be_a(Archfiend::Logging::DefaultFormatter)
      end
    end
  end
end
