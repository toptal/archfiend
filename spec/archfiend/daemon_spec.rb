RSpec.describe Archfiend::Daemon do
  describe '.daemonize' do
    it 'calls all tasks' do
      expect(Process).to receive(:daemon).with(nil, true)
      expect(described_class).to receive(:handle_pid_file).with('pid_file')
      expect(described_class).to receive(:close_io)
      expect(described_class).to receive(:redirect_std_io).with('log_file')
      expect(described_class).to receive(:set_process_title).with('app_name', 'app_env')
      expect(described_class).to receive(:srand)

      described_class.daemonize(
        pid_file: 'pid_file',
        log_file: 'log_file',
        app_name: 'app_name',
        app_env: 'app_env'
      )
    end
  end

  describe '.set_process_title' do
    it 'calls Process.setproctitle' do
      expect(Process).to receive(:setproctitle).with('Test (development)')
      described_class.set_process_title('Test', 'development')
    end
  end

  describe '.handle_pid_file' do
    subject { described_class.handle_pid_file(pid_file) }
    let(:temp_dir) { Dir.mktmpdir }
    let(:pid_file) { File.join(temp_dir, 'test.pid') }

    after { FileUtils.remove_entry_secure(temp_dir) }

    context 'when pid file does not exist' do
      it 'creates pid file with correct content' do
        allow(Process).to receive(:pid).and_return(666)
        subject
        expect(File.read(pid_file)).to match("666\n")
      end

      context 'when pid file creation fails' do
        let(:pid_file) { '/tmp/incorrect_dir/test.pid' }

        it 'aborts with relevant message' do
          expect { subject }.to raise_exception(SystemExit, /\APid file creation failed/)
        end
      end
    end

    context 'when pid file already exists' do
      before { FileUtils.touch(pid_file) }

      it 'aborts with relevant message' do
        expect { subject }.to raise_exception(SystemExit, /the daemon is already running/)
      end
    end
  end
end
