RSpec.describe Archfiend::ThreadLoop do
  let(:logger) { instance_double(Logger, info: true) }
  let(:app) { instance_double(Archfiend::Application, logger: logger) }
  let(:subclass) do
    Class.new(described_class) do
      def run
        logger.info('#run called')
      end
    end
  end
  let(:foo_bar_loop) { stub_const('FooBarLoop', subclass) }

  after do
    described_class.instance_variable_set('@subclasses', nil)
  end

  describe '.inherited' do
    it 'registers the subclass' do
      foo_bar_loop
      expect(described_class.subclasses).to eq([FooBarLoop])
    end
  end

  describe '.start_all' do
    subject { described_class.start_all(app) }

    context 'when subclasses are present' do
      before { foo_bar_loop }

      it 'starts threads' do
        expect(logger).to receive(:info).with('#run called')
        started_threads = subject
        expect(started_threads.map { |th| th[:name] }).to match(['FooBarLoop'])
        # The #run method does not block, so we can wait until thread finishes ensuring the logger call
        started_threads.map(&:join)
      end
    end

    context 'when there are no subclasses' do
      it 'does not fail' do
        subject
      end
    end
  end

  describe '#run' do
    subject { foo_bar_loop.new.tap { |fbl| fbl.app = app }.run }

    let(:subclass) do
      Class.new(described_class) do
        def iterate
          @counter ||= 0
          @counter += 1
          fail Exception, 'Iterate called three times' if @counter > 2
        end
      end
    end

    it 'loops' do
      expect { subject }.to raise_exception(Exception, 'Iterate called three times')
    end

    context 'when #iterate raises RuntimeError' do
      let(:subclass) do
        Class.new(described_class) do
          def iterate
            @counter ||= 0
            @counter += 1
            fail Exception, 'Iterate called two times' if @counter > 1

            fail 'Regular runtime error'
          end
        end
      end

      before do
        stub_const('Archfiend::ThreadLoop::EXCEPTION_DELAY', 0.001)
      end

      it 'is logged' do
        expect(logger).to receive(:error) do |log_hash|
          expect(log_hash[:message]).to eq('Regular runtime error')
          expect(log_hash[:backtrace]).to be_a(Array)
        end
        expect { subject }.to raise_exception(Exception, 'Iterate called two times')
      end
    end
  end
end
