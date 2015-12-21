require_relative '../../log/logger'
require_relative '../../git/git-parser'
require_relative '../../git/repo'
require_relative '../../artifacts/repo-artifacts'
require_relative '../../init'

module CsBuilder
  module Commands
    module Artifacts
      class List

        include CsBuilder::Git
        include CsBuilder::Artifacts

        def initialize(config_dir)
          CsBuilder::Init.init_cs_builder_dir(config_dir)
          @config_dir = config_dir
          @log = CsBuilder::Log.get_logger("list")
        end
        
        def run(options)
          @log.debug("options: #{options}")
          Dir["#{@config_dir}/artifacts/**/*.tgz"]
        end
      end
    end
  end
end
