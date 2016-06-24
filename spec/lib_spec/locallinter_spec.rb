require_relative '../spec_helper.rb'
RSpec.describe LocalLinter do
  before do
    allow_any_instance_of(BlissLogger).to receive(:log_to_papertrail).and_return(true)
  end

  before(:all) do
    @output_file = "#{Dir.pwd}/spec/fixtures/result.txt"
    FileUtils.touch(@output_file)
    @params = {
      log_prefix: 'test',
      git_dir: "#{Dir.pwd}/spec/fixtires/projs/php",
      output_file: @output_file,
      commit: 'master',
      remove_open_source: false,
      excluded_dirs: [],
      linter_config_path: "#{Dir.pwd}/spec/fixtures/docker/linters/phpcs.yml"
    }
  end

  after(:all) do
    File.delete(@output_file) if File.exist?(@output_file)
  end

  context 'local linter' do
    it 'should abort with bad git_dir' do
      expect do
        LocalLinter.new(log_prefix: 'test', git_dir: '/blah/some_non_existent_dir')
      end.to raise_error SystemExit
    end

    it 'should abort with bad output file' do
      expect do
        LocalLinter.new(log_prefix: 'test', git_dir: Dir.pwd)
      end.to raise_error SystemExit
    end

    it 'should abort with bad output file' do
      expect do
        LocalLinter.new(log_prefix: 'test', git_dir: Dir.pwd)
      end.to raise_error SystemExit
    end

    it 'pass configuration with valid params' do
      expect do
        LocalLinter.new(params)
      end.not_to raise_error SystemExit
    end
  end
end
