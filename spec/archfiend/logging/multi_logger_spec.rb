RSpec.describe Archfiend::Logging::MultiLogger do
  subject(:instance) { described_class.new(loggers) }

  let(:logger1) { instance_double(Logger) }
  let(:logger2) { instance_double(Logger) }
  let(:loggers) { [logger1, logger2] }

  describe '#method_missing' do
    subject { instance.info('test') }

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
        expect { instance.unknown_method('test') }.to raise_exception(NoMethodError)
      end
    end
  end
end
