require_relative '../../log/logger'
require_relative '../../init'

module CsBuilder
  module Commands
    module Artifacts
      class List

        def initialize(config_dir, store)
          CsBuilder::Init.init_cs_builder_dir(config_dir)
          @config_dir = config_dir
          @log = CsBuilder::Log.get_logger("list")
          @store = store
        end
        
        def run(org:, repo:)
          @log.debug("org: #{org}, repo: #{repo}")
          artifacts = @store.list_artifacts(org, repo)
          artifacts.map{ |a| 
            "#{a[:key]} local: #{a[:local]}, remote: #{a[:remote]}"
          }.join("\n")
        end
      end
    end
  end
end
