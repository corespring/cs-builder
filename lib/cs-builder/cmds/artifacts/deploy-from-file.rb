require_relative '../../log/logger'
require_relative './deploy-cmd'
require_relative '../../git/hash-and-tag'

include CsBuilder::Git 

module CsBuilder
  module Commands
    module Artifacts

      class DeployFromFile < DeployCommand

        def initialize(config_dir, file, tag:, hash: 'no-hash')
          super(config_dir)
          @log = CsBuilder::Log.get_logger("deploy-from-file")
          @file = file
          @tag = tag
          @hash = hash
        end
      

        def load_artifact
          if File.exists?(@file)
            { :path => @file,
              :hash_and_tag => HashAndTag.new(@hash, @tag),
              :version => @tag.gsub("v", "") }
          end
        end 

      end        

    end
  end
end

