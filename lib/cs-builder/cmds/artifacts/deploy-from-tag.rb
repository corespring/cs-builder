module CsBuilder
  module Commands
    module Artifacts
      class DeployFromTag

        def initialize(config_dir)
          CsBuilder::Init.init_cs_builder_dir(config_dir)
          @config_dir = config_dir
          @log = CsBuilder::Log.get_logger(self.class.name)
        end
        
        def run(options)
          @log.debug("options: #{options}")
        end
      end
    end
  end
end
