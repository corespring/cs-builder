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
          raise "shell command: [#{cmd}] - threw an error" if $?.to_i != 0
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

      def mkdir_if_needed(p)
        unless File.directory? p
          FileUtils.mkdir(p)
        end
      end

      private

      def init_build_dir
        if(File.exists? @config_dir)
          @log.debug "config dir already exists - skip initialisation"
        else
          @log.debug "config dir doesn't exist - #{@config_dir}"
          default_config = "#{File.expand_path(File.dirname(__FILE__))}/../../../.default-config/."
          @log.debug("mkdir: #{@config_dir}")
          FileUtils.mkdir(@config_dir)
          FileUtils.cp_r(default_config, @config_dir)
        end

        # create some dirs if needed
        mkdir_if_needed(File.join(@config_dir, "repos") )
        mkdir_if_needed(File.join(@config_dir, "slugs") )
        mkdir_if_needed(File.join(@config_dir, "binaries") )
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
