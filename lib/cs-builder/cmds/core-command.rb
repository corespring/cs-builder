require_relative '../log/logger'
require_relative '../shell/runner'
require_relative '../io/utils'

module CsBuilder
  module Commands
    class CoreCommand

      include CsBuilder::ShellRunner
      include CsBuilder::Log
      include CsBuilder::IO::Utils

      @config_dir = File.expand_path("~/.cs-builder")

      def initialize(name, config_dir, init: true)
        @config_dir = config_dir
        @log = Log.get_logger(name)
        @log.debug("config_dir: #{@config_dir}")
        init_build_dir if init
      end

      protected

      def run_cmd(cmd, strip_ansi: true)
        @log.debug "[run] -> #{cmd}"
        run_shell_cmd(cmd, strip_ansi: strip_ansi)
      end

      private

      def init_build_dir
        if(File.exists? @config_dir)
          @log.debug "config dir already exists - skip initialisation"
        else
          @log.debug "config dir doesn't exist - #{@config_dir}"
          default_config = "#{File.expand_path(File.dirname(__FILE__))}/../../../.default-config/."
          @log.debug("mkdir: #{@config_dir}")
          FileUtils.mkdir_p(File.expand_path(@config_dir))
          FileUtils.cp_r(default_config, File.expand_path(@config_dir))
        end

        # create some dirs if needed
        mkdir_if_needed(File.join(@config_dir, "repos") )
        mkdir_if_needed(File.join(@config_dir, "slugs") )
        mkdir_if_needed(File.join(@config_dir, "binaries") )
        mkdir_if_needed(File.join(@config_dir, "artifacts") )
      end

    end
  end
end
