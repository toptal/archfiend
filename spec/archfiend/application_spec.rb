require 'active_record'
require 'active_support/time'
require 'config'

RSpec.describe Archfiend::Application do
  subject(:app) { application_class.new }

  let!(:utils) do
    stub_const(
      'FooBar',
      Module.new do
        extend Archfiend::Utilities

        def self.root
          Pathname.new(File.expand_path('spec/fixtures'))
        end
      end
    )
  end

  let(:application_class) do
    stub_const(
      'FooBar::Application',
      Class.new(described_class) do
        def utils
          ::FooBar
        end
      end
    )
  end

  describe '#run' do
    subject { app.run }

    before do
      allow(app).to receive(:loop)
      allow(app).to receive(:setup_cleanup) # at_exit is global, so don't allow setting it
    end

    it 'calls #setup_cleanup after setup and starting of ThreadLoop and SubprocessLoop' do
      expect(app).to receive(:setup_cleanup) { fail 'SetupCleanup' }

      expect(app).to receive(:setup).and_call_original
      expect(Archfiend::ThreadLoop).to receive(:start_all)
      expect(Archfiend::SubprocessLoop).to receive(:start_all)

      expect { subject }.to raise_exception('SetupCleanup')
    end

    it 'loops after #setup, starting of ThreadLoop, SubprocessLoop and #setup_cleanup' do
      expect(app).to receive(:loop) { fail 'Loop' }

      expect(app).to receive(:setup).and_call_original
      expect(Archfiend::ThreadLoop).to receive(:start_all)
      expect(Archfiend::SubprocessLoop).to receive(:start_all)
      expect(app).to receive(:setup_cleanup)

      expect { subject }.to raise_exception('Loop')
    end

    context 'when Clockwork module is defined' do
      let!(:clockwork) { stub_const('::Clockwork', Module.new) }

      it 'calls Clockwork.run' do
        expect(clockwork).to receive(:run)
        subject
        Thread.list.find { |th| th[:name] == 'Clockwork' }.join
      end
    end

    context 'when Clockwork module is not defined' do
      it 'does not fail' do
        expect { subject }.not_to raise_exception
      end
    end
  end

  describe '#setup' do
    subject { app.setup }

    let(:env) { 'test' }
    let(:logger) { instance_double(Logger, 'level=': true, 'progname=': true) }

    before do
      allow(app).to receive(:env).and_return(env)
      allow(app.utils).to receive(:logger).and_return(logger)
    end

    after do
      ActiveRecord::Base.logger = nil
      ActiveRecord::Base.configurations = {}
    end

    it 'sets up logger' do
      expect(logger).to receive(:level=).with(:info)
      subject
    end

    it 'sets up ActiveRecord configurations' do
      subject
      expect(ActiveRecord::Base.configurations)
        .to match(YAML.load(IO.read(utils.root.join('config', 'database.yml')))) # rubocop:disable Security/YAMLLoad
    end

    shared_examples 'establishes ActiveRecord connection' do |env|
      it 'establishes ActiveRecord connection' do
        expect(ActiveRecord::Base).to receive(:establish_connection).with(env)
        subject
      end
    end

    shared_examples 'sets ActiveRecord logger' do
      it 'sets ActiveRecord logger' do
        expect { subject }.to change { ActiveRecord::Base.logger }.to(logger)
      end
    end

    shared_examples 'does not set ActiveRecord logger' do
      it 'does not set ActiveRecord logger' do
        expect { subject }.not_to change { ActiveRecord::Base.logger }
      end
    end

    context 'when test environment' do
      include_examples 'establishes ActiveRecord connection', :test
      include_examples 'sets ActiveRecord logger'
    end

    context 'when development environment ' do
      let(:env) { 'development' }

      include_examples 'establishes ActiveRecord connection', :development
      include_examples 'sets ActiveRecord logger'
    end

    context 'when staging environment' do
      let(:env) { 'staging' }

      include_examples 'establishes ActiveRecord connection', :staging
      include_examples 'does not set ActiveRecord logger'
    end

    context 'when production environment' do
      let(:env) { 'production' }

      include_examples 'does not set ActiveRecord logger'
      include_examples 'establishes ActiveRecord connection', :production
    end

    it 'sets up settings' do
      subject
      expect(Settings.app_name).to eq('FooBar')
    end

    it 'runs only once' do
      subject
      expect(app).not_to receive(:setup_activerecord)
      expect(app).not_to receive(:setup_settings)
      subject
    end
  end

  describe '#env' do
    it 'delegates to utils' do
      expect(utils).to receive(:env)
      subject.env
    end
  end

  describe Archfiend::Utilities do
    subject(:utils) { foo_bar }

    let(:utils_module) do
      Module.new do
        extend Archfiend::Utilities

        def self.root
          Pathname.new(File.expand_path('spec/fixtures'))
        end
      end
    end

    let!(:foo_bar) { stub_const('FooBar', utils_module) }

    let!(:application_class) { stub_const('FooBar::Application', Class.new) }

    describe '#logger' do
      subject { utils.logger }

      let(:logger) { instance_double(Logger) }

      it 'calls Archfiend::Logging.create' do
        expect(Archfiend::Logging).to receive(:create).with('test', Pathname.new(File.expand_path('spec/fixtures/log')))
        subject
      end

      it 'memoizes the logger' do
        expect(Archfiend::Logging).to receive(:create).once.and_return(logger)
        utils.logger
        expect(utils.logger).to eq(logger)
      end
    end

    describe '#app' do
      subject { utils.app }

      it 'instantiates the application' do
        expect(subject).to be_a(application_class)
      end

      it 'memoizes the application' do
        instance = utils.app
        expect(utils.app).to eq(instance)
      end
    end

    describe '#env' do
      subject { utils.env }

      let(:app_env) { 'test' }
      let(:rails_env) { 'staging' }

      before do
        ENV['APP_ENV'] = app_env
        ENV['RAILS_ENV'] = rails_env
      end

      after do
        ENV['APP_ENV'] = 'test'
        ENV.delete('RAILS_ENV')
      end

      context 'when APP_ENV is set' do
        it { is_expected.to eq('test') }
      end

      context 'when APP_ENV is not set' do
        let(:app_env) { nil }

        it { is_expected.to eq('staging') }
      end

      context 'when APP_ENV and RAILS_ENV are not set' do
        let(:app_env) { nil }
        let(:rails_env) { nil }

        it { is_expected.to eq('development') }
      end
    end

    describe '#groups' do
      subject { utils.groups(*groups_args) }

      let(:groups_args) { [] }
      let(:env) { 'development' }

      before do
        allow(utils).to receive(:env).and_return(env)
      end

      context 'when development environment' do
        it { is_expected.to match_array(%i[default development]) }
      end

      context 'when test environment' do
        let(:env) { 'test' }

        it { is_expected.to match_array(%i[default test]) }
      end

      context 'when staging environment' do
        let(:env) { 'staging' }

        it { is_expected.to match_array(%i[default staging]) }
      end

      context 'when production environment' do
        let(:env) { 'production' }

        it { is_expected.to match_array(%i[default production]) }
      end
    end
  end
end
