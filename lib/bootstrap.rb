# Bootstrap required libraries
require 'open3'
require 'yaml'
require 'colorize'
require 'logger'
require 'fileutils'
require 'mechanize'
require 'date'
require 'faraday'
require 'figaro'
require 'securerandom'
require 'parallel'
require 'thread'
$HTTP_MUTEX = Mutex.new
Figaro::Application.new(path: 'application.yml').load
require_relative 'util/copyright'
require_relative 'util/opensourcematches'
require_relative 'util/common'
require_relative 'util/cmd'
require_relative 'util/gitbase'
require_relative 'util/aws_uploader'
require_relative 'util/sourcescrubber'
require_relative 'util/blisslogger'
require_relative 'util/partitioner'
require_relative 'util/directoryanalyzer'
require_relative 'util/statsmerger'
require_relative 'initializer/initializer'
require_relative 'gitlogger/gitlogger'
require_relative 'collectortask'
require_relative 'concurrenttasks'
require_relative 'stats/stats'
require_relative 'stats/localstats'
require_relative 'stats/statstask'
require_relative 'linter/linter'
require_relative 'linter/locallinter'
require_relative 'linter/lintertask'
require_relative 'exceptions/linter_exception'
require_relative 'initializer/firstpass'
