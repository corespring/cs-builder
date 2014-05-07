require_relative './core-command'

module CsBuilder
  module Commands

    class RemoveConfig < CoreCommand

      def initialize(config_dir)
        super('remove_config', 'DEBUG', config_dir, init: false)
      end

      def run
        FileUtils.rm_rf(@config_dir)
      end

    end

  end
end
