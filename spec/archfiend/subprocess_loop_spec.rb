RSpec.describe Archfiend::SubprocessLoop do
  let(:logger) { instance_double(Logger, info: true) }
  let(:app) { instance_double(Archfiend::Application, logger: logger) }
  let(:subclass) do
    Class.new(described_class) do
      def iterate
        sleep 0.01
      end
    end
  end
  let(:foo_bar_loop) { stub_const('FooBarLoop', subclass) }

  after do
    described_class.instance_variable_set('@subclasses', nil)
    described_class.instance_variable_set('@subprocess_pids', nil)
  end

  describe '.inherited' do
    it 'registers the subclass' do
      foo_bar_loop
      expect(described_class.subclasses).to eq([FooBarLoop])
      expect(described_class.subprocess_pids).to eq([])
    end
  end

  describe '.start_all' do
    subject { described_class.start_all(app) }

    context 'when subclasses are present' do
      before { foo_bar_loop }

      it 'forks and keeps the PID' do
        expect { subject }.to change(described_class, :subprocess_pids).from([])
        sub_pid = described_class.subprocess_pids[0]
        expect(process_exists?(sub_pid)).to be true
        described_class.kill_all
      end
    end

    context 'when there are no subclasses' do
      it 'does not fail' do
        subject
      end
    end
  end

  describe '.kill_all' do
    subject { described_class.kill_all }

    context 'when subprocess_pids is empty' do
      it 'does not fail' do
        subject
      end
    end

    context 'when subprocess_pids are present' do
      let(:subprocess_pid) { described_class.subprocess_pids.last }

      before do
        foo_bar_loop
        described_class.start_all(app)
      end

      it 'kills subprocesses' do
        expect(subprocess_pid).not_to be_nil
        expect { subject }.to change_with_timeout { process_exists?(subprocess_pid) }.from(true).to(false)
      end

      it 'does not fail on stale pids' do
        incorrect_process_id = 65_536
        described_class.subprocess_pids.unshift(incorrect_process_id)
        expect { subject }.to change_with_timeout { process_exists?(subprocess_pid) }.from(true).to(false)
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
        stub_const('Archfiend::SubprocessLoop::EXCEPTION_DELAY', 0.001)
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

  def process_exists?(pid)
    Process.kill(0, pid) == 1
  rescue Errno::ESRCH, Errno::EPERM
    false
  end
end
