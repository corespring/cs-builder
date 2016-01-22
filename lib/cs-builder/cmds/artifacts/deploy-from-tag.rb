require_relative '../../log/logger'
require_relative './deploy-cmd'


module CsBuilder
  module Commands
    module Artifacts

      class DeployFromTag < DeployCommand
        
        extend NilCheck 

        def self.build(config_dir, store, tag, git_url:, org: nil, repo_name: nil)
          org = nil_or_empty?(org) ? Git::GitUrlParser.org(git_url) : org
          repo_name = nil_or_empty?(repo_name) ? Git::GitUrlParser.repo(git_url) : repo_name
          CsBuilder::Log.get_logger('deploy-from-tag').info("[#{__method__}] org: #{org}, repo_name: #{repo_name}")
          repo = Repo.new(config_dir, git_url, org, repo_name, "master")
          DeployFromTag.new(config_dir, store, repo, tag)
        end

        def initialize(config_dir, store, repo, tag)
          super(config_dir)
          @log = CsBuilder::Log.get_logger("deploy-from-tag")
          @repo = repo
          @repo.clone_and_update
          @tag = tag
          @store = store
        end

        def load_artifact
          @log.info(__method__)
          hash = @repo.hash_for_tag(@tag)
          if hash.nil?
            @log.warn("Can't find hash for tag: #{@tag}")
            nil
          else
            @log.debug("#{__method__} org: #{@repo.org}, repo: #{@repo.repo},  hash: #{hash}")
            @store.artifact_from_hash(@repo.org, @repo.repo, hash)
          end
        end

      end
    end
  end
end
