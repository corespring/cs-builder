require_relative '../../log/logger'
require_relative './deploy-cmd'


module CsBuilder
  module Commands
    module Artifacts

      class DeployFromTag < DeployCommand

        def self.build(config_dir, store, tag, git_url:, org: nil, repo_name: nil)
          org = org or Git::GitUrlParser.org(git_url)
          repo_name = repo_name or Git::GitUrlParser.repo(git_url)
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
            @store.artifact_from_hash(@repo.org, @repo.repo, hash)
          end
        end

      end
    end
  end
end
