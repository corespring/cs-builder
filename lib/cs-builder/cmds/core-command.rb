require_relative '../log/logger'
require_relative '../shell/runner'
require_relative '../io/utils'
require_relative '../init'

module CsBuilder
  module Commands
    class CoreCommand

      include CsBuilder::ShellRunner
      include CsBuilder::Log
      include CsBuilder::Init
      include CsBuilder::IO::Utils

      @config_dir = File.expand_path("~/.cs-builder")

      def initialize(name, config_dir, init: true)
        @config_dir = config_dir
        @log = Log.get_logger(name)
        @log.debug("config_dir: #{@config_dir}")
        Init.int_cs_builder_dir(@config_dir) if init
      end

      protected
      def run_cmd(cmd, strip_ansi: true)
        @log.debug "[run] -> #{cmd}"
        run_shell_cmd(cmd, strip_ansi: strip_ansi)
      end

    end
  end
end
