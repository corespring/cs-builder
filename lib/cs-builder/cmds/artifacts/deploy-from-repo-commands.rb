require_relative '../../log/logger'
require_relative './deploy-cmd'
require_relative '../../bucket'
require_relative '../../artifacts/store/remote-and-local-store'


module CsBuilder
  module Commands
    module Artifacts


      class DeployFromBranch < DeployCommand

        def self.build(config_dir, store, git_url:, branch:, org: nil, repo_name: nil, bucket_name: CsBuilder::BUCKET)
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
          @store.artifact(@repo.org, @repo.repo, @repo.hash_and_tag)
        end

      end

      class DeployFromTag < DeployCommand

        def initialize(config_dir, store, org, repo_name, tag)
          super(config_dir)
          @log = CsBuilder::Log.get_logger("deploy-from-tag")
          @org = org
          @repo_name = repo_name
          @tag = tag
          @store = store
        end

        def load_artifact
          @store.artifact_from_tag(@org, @repo_name, @tag)
        end

      end
    end
  end
end
