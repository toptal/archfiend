RSpec.describe Archfiend::Generators::Utils do
  # TODO: add specs for multiple arguments for both methods

  describe '.find_file' do
    subject { described_class.find_file(file_name) }

    context 'when file exists' do
      let(:file_name) { 'spec_helper.rb' }

      around do |example|
        old_pwd = Dir.pwd
        FileUtils.cd(File.join('spec', 'archfiend'))
        example.call
        FileUtils.cd(old_pwd)
      end

      it { is_expected.to eq(File.expand_path(File.join(Dir.pwd, '..', 'spec_helper.rb'))) }
    end

    context 'when file does not exist' do
      let(:file_name) { 'foobar.baz' }

      it { is_expected.to be nil }
    end
  end

  describe '.find_directory' do
    subject { described_class.find_directory(directory_name) }

    context 'when directory exists' do
      let(:directory_name) { 'spec' }

      around do |example|
        old_pwd = Dir.pwd
        FileUtils.cd(File.join('spec', 'archfiend'))
        example.call
        FileUtils.cd(old_pwd)
      end

      it { is_expected.to eq(File.expand_path(File.join(Dir.pwd, '..'))) }
    end

    context 'when directory does not exist' do
      let(:directory_name) { 'foo_bar_baz' }

      it { is_expected.to be nil }
    end
  end
end
