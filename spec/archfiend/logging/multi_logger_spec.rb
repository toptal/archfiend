RSpec.describe Archfiend::Logging::MultiLogger do
  subject(:multi_logger) { described_class.new(loggers) }

  let(:logger1) { instance_double(Logger) }
  let(:logger2) { instance_double(Logger) }
  let(:loggers) { [logger1, logger2] }

  describe '#method_missing' do
    subject { multi_logger.info('test') }

    context 'when there are responding loggers' do
      it 'forwards method to all responding loggers' do
        expect(logger1).to receive(:info).with('test').and_return('retval1')
        expect(logger2).to receive(:info).with('test').and_return('retval2')

        expect(subject).to eq('retval1')
      end
    end

    context 'when there are no loggers' do
      let(:loggers) { [] }

      it 'fails with NoMethodError' do
        expect { subject }.to raise_exception(NoMethodError)
      end
    end

    context 'when there are no responding loggers' do
      it 'fails with NoMethodError' do
        expect { multi_logger.unknown_method('test') }.to raise_exception(NoMethodError)
      end
    end
  end

  describe '#info' do
    let(:logger1) { Logger.new(log1) }
    let(:logger2) { Logger.new(log2) }
    let(:log1) { StringIO.new }
    let(:log2) { StringIO.new }

    specify '#info(message)' do
      expect do
        expect do
          multi_logger.info('the message')
        end.to change(log1, :string).to(/INFO -- : the message/)
      end.to change(log2, :string).to(/INFO -- : the message/)
    end

    specify '#info { message }' do
      expect do
        expect do
          multi_logger.info { 'the message' }
        end.to change(log1, :string).to(/INFO -- : the message/)
      end.to change(log2, :string).to(/INFO -- : the message/)
    end

    specify '#info(progname) { message }' do
      expect do
        expect do
          multi_logger.info('The App') { 'the message' }
        end.to change(log1, :string).to(/INFO -- The App: the message/)
      end.to change(log2, :string).to(/INFO -- The App: the message/)
    end
  end
end
