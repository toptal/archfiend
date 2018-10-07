RSpec.describe Archfiend::Logging::JSONFormatter do
  before do
    Thread.current[:tid] = 'TESTTID'
    allow(Process).to receive(:pid).and_return(666)
  end

  after { Thread.current[:tid] = nil }

  describe '#call' do
    subject { described_class.new.call(severity, datetime, progname, msg) }

    let(:severity) { 'INFO' }
    let(:datetime) { Time.parse('2018-03-16 12:00:00 UTC') }
    let(:progname) { 'Test' }

    context 'when msg is a hash' do
      let(:msg) { {message: 'Test', backtrace: %w[line1 line2 line3]} }

      it 'is returns a correct json' do
        expect(subject).to eq(%({"@timestamp":"2018-03-16T12:00:00.000Z","loglevel":"info","pid":666,"tid":"TESTTID","type":"archfiend","message":"Test","backtrace":["line1","line2"],"app":"Test"}\n))
      end
    end

    context 'when msg is a string' do
      let(:msg) { 'Test' }

      before do
        allow_any_instance_of(described_class).to receive(:caller).and_return(Array.new(10, &:to_s))
      end

      it 'is returns a correct json' do
        expect(subject).to eq(%({"@timestamp":"2018-03-16T12:00:00.000Z","loglevel":"info","pid":666,"tid":"TESTTID","type":"archfiend","message":"Test","backtrace":["8","9"],"app":"Test"}\n))
      end
    end
  end
end
