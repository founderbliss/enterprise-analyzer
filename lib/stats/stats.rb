module Stats
  def execute_stats_cmd(commit, directory = nil)
    stats = git_stats(commit)
    checkout_commit(@git_dir, commit)
    directory = @git_dir if directory.nil?
    all_stats = {
      commit: commit,
      added_lines: stats[:added_lines], deleted_lines: stats[:deleted_lines],
      total_cloc: cloc_total(directory), cloc: cloc_original(directory),
      cloc_tests: cloc_tests(directory)
    }
    all_stats
  end

  def post_stats(stats)
    @logger.info("\tPosting commit stats to Bliss...")
    stats[:repo_key] = @repo_key
    stats_response = http_post("#{@host}/api/commit/stats", stats)
    return if stats_response.nil?
    @logger.success("\tSuccessfully saved stats for commit #{stats[:commit]}.")
  end

  def cloc_total(directory)
    @logger.info("\tCounting total lines of code. This may take a while...")
    `#{cloc_cmd(directory)}`
  end

  def cloc_original(directory)
    remove_open_source_files(directory) unless @repo['detect_open_source'] == false
    remove_excluded_directories(@excluded_dirs, directory)
    @logger.info("\tCounting original lines of code. This may take a while...")
    `#{cloc_cmd(directory)}`
  end

  def cloc_cmd(directory)
    "perl #{cloc_command} #{directory} #{cloc_options}"
  end

  def cloc_tests(directory)
    @logger.info("\t#{@name} - Counting lines of test code. This may take a while...")
    test_dirs = get_test_dirs(directory, @repo_test_files, @repo_test_dirs)
    if !test_dirs.empty?
      cmd = "perl #{cloc_command} #{test_dirs} #{cloc_options}"
      cloc_tests = `#{cmd}`
    else
      @logger.warn("\tNo known test pattern for cloc to run - skipped")
      cloc_tests = nil
    end
    cloc_tests
  end

  def git_numstat(commit)
    stats = `cd #{@git_dir} && git log --pretty=tformat: --numstat #{commit}`
    stats.split("\n")
  end

  def git_stats(commit)
    @logger.info("\tGetting stats for #{commit}...")
    added_lines = 0
    deleted_lines = 0
    git_numstat(commit).each do |stt|
      match = stt.match(/(\d+)\t(\d+)/)
      next unless match
      added_lines += match[1].to_i
      deleted_lines += match[2].to_i
    end
    { added_lines: added_lines, deleted_lines: deleted_lines }
  end
end
