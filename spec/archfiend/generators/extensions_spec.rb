RSpec.describe Archfiend::Generators::Extensions do
  subject(:instance) { described_class.new(generator_options, action_context, generator_name) }

  let(:generator_options) { instance_double(Archfiend::Generators::Options, extensions: extensions) }
  let(:action_context) { Class.new(Thor::Group).new }
  let(:generator_name) { 'daemon' }
  let(:extensions) { [] }

  describe '#initialize' do
    it 'activates extensions' do
      expect_any_instance_of(described_class).to receive(:activate_extensions).and_call_original
      subject
      expect(subject.instance_variable_get('@extensions')).to eq([])
    end

    it 'exposes extensions' do
      expect_any_instance_of(described_class).to receive(:expose_extensions).and_call_original
      subject
    end
  end

  describe '#run_with_init_callbacks' do
    let(:block) { ->() {} }

    before do
      allow(instance).to receive(:generator_extensions).and_return(generator_extensions)
    end

    context 'when there are extensions' do
      let(:generator_extensions) { [dummy_instance] }
      let(:dummy_instance) { Object.new }

      context 'when default action is not skipped' do
        context 'when generator extension has before_init' do
          before { allow(dummy_instance).to receive(:before_init) }

          it 'calls before_init' do
            expect(dummy_instance).to receive(:before_init)

            expect { |b| subject.run_with_init_callbacks(&b) }.to yield_control
          end
        end

        context 'when generator extension has after callback' do
          before { allow(dummy_instance).to receive(:after_init) }

          it 'calls before_init' do
            expect(dummy_instance).to receive(:after_init)

            expect { |b| subject.run_with_init_callbacks(&b) }.to yield_control
          end
        end

        context 'when generator extension has no callbacks' do
          it 'calls block' do
            expect { |b| subject.run_with_init_callbacks(&b) }.to yield_control
          end
        end
      end

      context 'when default action is skipped' do
        before do
          allow(dummy_instance).to receive(:skip_default_init_action?).and_return(true)
          allow(dummy_instance).to receive(:before_init)
          allow(dummy_instance).to receive(:after_init)
        end

        it 'does not call block' do
          expect(dummy_instance).to receive(:after_init)
          expect(dummy_instance).to receive(:before_init)

          expect { |b| subject.run_with_init_callbacks(&b) }.not_to yield_control
        end
      end
    end

    context 'when there are no extensions' do
      let(:generator_extensions) { [] }

      it 'calls the init action block' do
        expect { |b| subject.run_with_init_callbacks(&b) }.to yield_control
      end
    end
  end

  describe '#run_with_exec_callbacks' do
    let(:block) { ->() {} }

    before do
      allow(instance).to receive(:generator_extensions).and_return(generator_extensions)
    end

    context 'when there are extensions' do
      let(:generator_extensions) { [dummy_instance] }
      let(:dummy_instance) { Object.new }

      context 'when default action is not skipped' do
        context 'when generator extension has before callback' do
          before { allow(dummy_instance).to receive(:before_exec) }

          it 'calls before_init' do
            expect(dummy_instance).to receive(:before_exec)

            expect { |b| subject.run_with_exec_callbacks(&b) }.to yield_control
          end
        end

        context 'when generator extension has after callback' do
          before { allow(dummy_instance).to receive(:after_exec) }

          it 'calls before_init' do
            expect(dummy_instance).to receive(:after_exec)

            expect { |b| subject.run_with_exec_callbacks(&b) }.to yield_control
          end
        end

        context 'when generator extension has no callbacks' do
          it 'calls block' do
            expect { |b| subject.run_with_exec_callbacks(&b) }.to yield_control
          end
        end
      end

      context 'when default action is skipped' do
        before do
          allow(dummy_instance).to receive(:skip_default_exec_action?).and_return(true)
          allow(dummy_instance).to receive(:before_exec)
          allow(dummy_instance).to receive(:after_exec)
        end

        it 'does not call block' do
          expect(dummy_instance).to receive(:after_exec)
          expect(dummy_instance).to receive(:before_exec)
          expect { |b| subject.run_with_exec_callbacks(&b) }.not_to yield_control
        end
      end
    end

    context 'when there are no extensions' do
      let(:generator_extensions) { [] }

      it 'calls the exec action block' do
        expect { |b| subject.run_with_exec_callbacks(&b) }.to yield_control
      end
    end
  end

  describe '#activate_extensions' do
    subject { instance.__send__(:activate_extensions) }

    context 'when there are extensions' do
      let(:extensions) { ['dummy_extension'] }

      context 'when there is gem' do
        before do
          allow(Kernel).to receive(:gem).with('dummy_extension')
          allow(Kernel).to receive(:require).with('dummy_extension')
        end

        context 'when it has the DummyExtensions module' do
          before do
            stub_const('DummyExtension', Class.new)
          end

          it 'activates the extension' do
            expect { subject }.to output(/\AActivated extension gem DummyExtension/).to_stdout
            expect(subject).to eq([DummyExtension])
          end
        end

        context 'when it does not have the DummyExtensions module' do
          it 'exits with a message' do
            expect { subject }.to raise_exception(SystemExit)
              .and output(/\AFailed to recognize extension module DummyExtension in gem dummy_extension, aborting/)
              .to_stdout
          end
        end
      end

      context 'when there is no gem' do
        it 'exits with a message' do
          expect { subject }.to raise_exception(SystemExit)
            .and output(/\AUnable to load requested extension gem dummy_extension, aborting/)
            .to_stdout
        end
      end
    end

    context 'when there are no extensions' do
      it { is_expected.to eq([]) }
    end
  end

  describe '#generator_extensions' do
    subject { instance.__send__(:generator_extensions) }

    context 'when there are extensions' do
      let(:extensions) { ['dummy_extension'] }

      before do
        allow(Kernel).to receive(:gem).with('dummy_extension')
        allow(Kernel).to receive(:require).with('dummy_extension')
        stub_const('DummyExtension', Class.new)
      end

      context 'when extensions have Generators::Extension module' do
        let(:dummy_klass) { Class.new }
        let(:dummy_instance) { dummy_klass.new }

        before do
          stub_const('DummyExtension::Generators::DaemonExtensions', dummy_klass)
        end

        it 'initializes classes and returns instances' do
          expect(dummy_klass).to receive(:new).with(action_context, generator_options).and_return(dummy_instance)
          expect(subject).to eq([dummy_instance])
        end
      end

      context 'when extensions do not have Generators::Extension module' do
        it { is_expected.to eq([]) }
      end
    end

    context 'when there are no extensions' do
      it { is_expected.to eq([]) }
    end
  end

  describe '#expose_extensions' do
    context 'when there are extensions' do
      let(:extensions) { ['dummy_extension'] }
      let(:dummy_klass) { Class.new }
      let(:dummy_instance) { dummy_klass.new }

      before do
        allow(Kernel).to receive(:gem).with('dummy_extension')
        allow(Kernel).to receive(:require).with('dummy_extension')
        stub_const('DummyExtension', Class.new)
        stub_const('DummyExtension::Generators::DaemonExtensions', dummy_klass)
        allow(dummy_klass).to receive(:new).with(action_context, generator_options).and_return(dummy_instance)
      end

      context 'when generator_extension class does not provide explicit exposed_name' do
        it 'exposes the extension instance in action_context' do
          expect { subject }.to change { action_context.respond_to?(:dummy_extension) }.from(false).to(true)
          expect(action_context.dummy_extension).to eq(dummy_instance)
        end
      end

      context 'when generator_extension class provides explicit exposed_name' do
        before do
          allow(dummy_instance).to receive(:exposed_name).and_return('exposed_name')
        end

        it 'exposes the extension instance in action_context' do
          expect { subject }.to change { action_context.respond_to?(:exposed_name) }.from(false).to(true)
          expect(action_context.exposed_name).to eq(dummy_instance)
        end
      end

      context 'when generator_extension class provides conflicting exposed_name' do
        before do
          allow(dummy_instance).to receive(:exposed_name).and_return('to_s')
        end

        it 'exits with a message' do
          expect { subject }.to raise_exception(SystemExit)
            .and output(/Extension's exposed_name "to_s" conflicts with existing method/)
            .to_stdout
        end
      end
    end

    context 'when there are no extensions' do
      it 'does not fail' do
        subject
      end
    end
  end
end
