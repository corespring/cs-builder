require_relative '../../log/logger'
require_relative './deploy-cmd'

module CsBuilder
  module Commands
    module Artifacts

      class DeployFromFile < DeployCommand

        def initialize(config_dir)
          super(config_dir)
          @log = CsBuilder::Log.get_logger("deploy-from-file")
        end
      

        def load_artifact(options)
          path = options[:artifact_file]

          hash = options.has_key?(:hash) ? options[:hash] : 'no-hash'
          if File.exists?(path)
            {
              :path => path,
              :hash => hash,
              :tag => options[:tag],
              :version => options[:tag].gsub("v", "")
            }
          end
        end 

      end        

    end
  end
end

