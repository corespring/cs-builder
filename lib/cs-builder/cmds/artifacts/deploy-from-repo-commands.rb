require_relative '../../log/logger'
require_relative './deploy-cmd'

module CsBuilder
  module Commands
    module Artifacts

      class DeployFromBranch < DeployFromRepoCommand

        def initialize(config_dir)
          super(config_dir)
          @log = CsBuilder::Log.get_logger("deploy-from-branch")
        end
      
        def find_artifact_from_repo_artifacts(options, repo, artifacts)
          hash_and_tag = repo.hash_and_tag
          artifacts.artifact(hash_and_tag)
        end 

      end        

      class DeployFromTag < DeployFromRepoCommand

        def initialize(config_dir)
          super(config_dir)
          @log = CsBuilder::Log.get_logger("deploy-from-tag")
        end
      
        def find_artifact_from_repo_artifacts(options, repo, artifacts)
          tag = options[:tag]
          raise "The repo doesn't contain the tag: #{tag}" unless repo.has_tag?(options[:tag])
          artifacts.artifact_from_tag(tag)
        end 

      end        
    end
  end
end
