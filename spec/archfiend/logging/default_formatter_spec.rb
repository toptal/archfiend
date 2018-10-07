RSpec.describe Archfiend::Logging::DefaultFormatter do
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
      let(:msg) { {message: 'Test', backtrace: []} }

      it { is_expected.to eq("2018-03-16T12:00:00.000Z 666 TID-TESTTID INFO: Test\n") }
    end

    context 'when msg is a string' do
      let(:msg) { 'Test' }

      it { is_expected.to eq("2018-03-16T12:00:00.000Z 666 TID-TESTTID INFO: Test\n") }
    end
  end
end
