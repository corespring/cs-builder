require 'log4r'
require 'log4r/outputter/datefileoutputter'

module CsBuilder
  module Commands
    class CoreCommand

      @config_dir = File.expand_path("~/.cs-builder")

      Log4r.define_levels(*Log4r::Log4rConfig::LogLevels)

      def initialize(name, level, config_dir, init: true)

        @config_dir = config_dir
        log_level = str_to_log_level(level)
        @log = Log4r::Logger.new(name)
        @log.outputters << Log4r::StdoutOutputter.new('log_stdout') #, :level => Log4r::WARN )
        @log.level = log_level
        @log.debug("config_dir: #{@config_dir}")
        init_build_dir if init
      end

      protected

      def run_cmd(cmd)
        @log.debug "[run] -> #{cmd}"
        IO.popen(cmd) do |io|
          while line = io.gets
            # the heroku-helper adds this to reset the ansi command - strip it
            cleaned = line.chomp
            puts "#{cleaned}" unless cleaned == nil or cleaned.empty?
          end
          io.close
          raise "An error occured" if $?.to_i != 0
        end
      end

      def in_dir(dir)
        current = File.expand_path(Dir.pwd)
        Dir.chdir(dir)
        @log.debug("[in_dir] current dir #{Dir.pwd}")
        yield
        Dir.chdir(current)
        @log.debug("[in_dir] back to: #{Dir.pwd}")
      end

      def get_sha(org, repo, branch)
        path = repo_path(org, repo, branch)
        @log.debug "[get_sha] for path: #{path}"
        sha = `git --git-dir=#{path}/.git --work-tree=#{path} rev-parse --short HEAD`.strip
        raise "no sha" if sha.nil? or sha.empty?
        sha
      end

      def repo_path(org, repo, branch)
        "#{@config_dir}/repos/#{org}/#{repo}/#{branch}"
      end

      def binaries_path(org, repo, branch)
        "#{@config_dir}/binaries/#{org}/#{repo}/#{branch}"
      end

      def slug_path(org, repo, branch, sha, suffix: "")
        "#{@config_dir}/slugs/#{org}/#{repo}/#{branch}/sha" << suffix
      end

      def binary_archive_path(binary_path, sha, suffix: "")
        "#{binary_path}/#{sha}" << suffix
      end

      private

      def init_build_dir
        if(File.exists? @config_dir)
          @log.debug "config dir already exists - skip initialisation"
        else
          default_config = "#{File.expand_path(File.dirname(__FILE__))}/../../.default-config/."
          FileUtils.mkdir(@config_dir)
          FileUtils.cp_r(default_config, @config_dir)
        end
      end

      def str_to_log_level(s)
        case s.upcase
        when "FATAL"
          return 5
        when "ERROR"
          return 4
        when "WARN"
          return 3
        when "INFO"
          return 2
        when "DEBUG"
          return 1
        else
          return 2
        end
      end
    end
  end
end
