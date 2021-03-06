module Linter
  include Gitbase
  def lint_commit(linter, output_file, directory = nil)
    directory = @git_dir if directory.nil?
    quality_tool = linter['quality_tool']
    cmd = lint_command(linter, output_file, directory)
    cmd = "cd #{directory} && #{cmd}" if linter['cd_first']
    begin
      execute_linter_cmd(cmd, output_file, linter['name'], linter['error_code'])
    rescue LinterError => e
      @logger.error(e.message)
      @logger.bugsnag(e)
    rescue Errno::ENOENT => e
      @logger.error("Dependency Error: #{quality_tool} not installed or not configured correctly...")
      @logger.bugsnag(e)
    end
  end

  def lint_command(linter, output_file, directory = nil)
    directory = @git_dir if directory.nil?
    linter['quality_command'].gsub('git_dir', directory)
                             .gsub('file_name', output_file)
                             .gsub('proj_filename', '')
  end

  def execute_linter_cmd(cmd, file_name, linter_name, error_code)
    result = ''
    error_code = -1 if error_code.nil? || error_code.to_s.empty?
    thread_status = Open3.popen2e(cmd) do |_stdin, stdout_err, wait_thr|
      result += stdout_err.read
      wait_thr.value
    end
    if thread_status.exitstatus == error_code
      handle_error(linter_name, file_name, result)
    else
      fill_empty_file(linter_name, file_name) if File.read(file_name).strip.empty?
      File.write(file_name, @scrubber.scrub(File.read(file_name))) if @scrubber
    end
  end

  def handle_error(linter_name, file_name, result)
    if linter_name.eql?('nsp')
      NspError.new(file_name).handle_error
    elsif linter_name.eql?('rubocop-custom')
      RubocopError.new(result, file_name).handle_error
    else
      File.write(file_name, "#{result} - failtorundocker")
      fail LinterError, "#{linter_name}\n#{result}"
    end
  end

  def fill_empty_file(linter_name, file_name)
    empty_tag = nil
    if linter_name =~ /cpd/
      empty_tag = 'lines,tokens,occurrences'
    elsif linter_name =~ /stylint/
      empty_tag = "Stylint: 0 Errors.\nStylint: 0 Warnings."
    elsif linter_name =~ /tslint|lizard/
      empty_tag = 'No violations found.'
    end
    File.write(file_name, empty_tag) unless empty_tag.nil?
  end

  # Post lintfile to AWS and notify Bliss
  def post_lintfile_to_bliss(key, commit, linter_id)
    lint_payload = { commit: commit, repo_key: @repo_key,
                     linter_id: linter_id, lint_file_location: key,
                     git_dir: @git_dir, bucket: 'bliss-collector-files' }
    http_post("#{@host}/api/commit/lint", lint_payload)
  end

  def post_lintfile_to_aws(key, content)
    @logger.info("\tUploading lint results to AWS...")
    upload_to_aws('bliss-collector-files', key, content)
  end

  def partition_and_lint(linter, directory = nil)
    directory_to_analyze = directory.nil? ? @git_dir : directory
    parts = Partitioner.new(directory_to_analyze, @logger, linter).create_partitions
    multipart = parts.size > 1
    num_proc = parts.size
    num_proc = 8 if num_proc > 8
    @logger.info("\tRunning #{linter['quality_tool']} on #{@commit}... This may take a while...")
    Parallel.each_with_index(parts, in_processes: num_proc) do |part, index|
      result_path = multipart ? "/tmp/result_#{index}.txt" : @output_file
      lint_commit(linter, result_path, part)
    end
    consolidate_output if multipart
  end

  def consolidate_output
    FileUtils.touch(@output_file)
    File.truncate(@output_file, 0)
    Dir.glob('/tmp/result_*.txt').each do |r|
      File.open(@output_file, 'a') do |f|
        f.write("<--LintFilePartition-->\n#{File.read(r)}")
      end
    end
  end
end
