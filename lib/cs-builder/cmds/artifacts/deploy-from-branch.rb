require_relative '../../log/logger'
require_relative './deploy-cmd'


module CsBuilder
  module Commands
    module Artifacts

      class DeployFromBranch < DeployCommand

        def self.build(config_dir, store, git_url:, branch:, org: nil, repo_name: nil)
          org = org or Git::GitUrlParser.org(git_url)
          repo_name = repo_name or Git::GitUrlParser.repo(git_url)
          repo = Repo.new(config_dir, git_url, org, repo_name, branch)
          DeployFromBranch.new(config_dir, store, repo)
        end

        def initialize(config_dir, store, repo)
          super(config_dir)
          @repo = repo
          @repo.clone_and_update
          @store = store
          @log = CsBuilder::Log.get_logger("deploy-from-branch")
        end

        def load_artifact
          @log.debug("[#{__method__}] org: #{@repo.org}, repo: #{@repo.repo}, hash_and_tag: #{@repo.hash_and_tag}")
          @store.artifact(@repo.org, @repo.repo, @repo.hash_and_tag)
        end

      end
    end
  end
end
