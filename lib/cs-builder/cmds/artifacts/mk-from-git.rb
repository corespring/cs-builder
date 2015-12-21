require_relative '../../log/logger'
require_relative '../../git/git-parser'
require_relative '../../git/repo'
require_relative '../../runner'
require_relative '../../artifacts/repo-artifacts-builder'
require_relative '../../init'

module CsBuilder
  module Commands
    module Artifacts
      class MkFromGit

        include CsBuilder::Runner
        include CsBuilder::Git
        include CsBuilder::Artifacts

        def initialize(config_dir, store)
          CsBuilder::Init.init_cs_builder_dir(config_dir)
          @config_dir = config_dir
          @log = CsBuilder::Log.get_logger("make-artifact-git")
          @store = store
        end

        def run(git_url:, branch:, cmd:, artifact:, org: nil, repo_name: nil, force: false)

          @log.debug("#{__method__} git_url: #{git_url}, org: #{org.class.name}" )

          org = org.nil? ? GitUrlParser.org(git_url) : org
          repo_name = repo_name.nil? ? GitUrlParser.repo(git_url) : repo_name

          repo = Repo.new(@config_dir, git_url, org, repo_name, branch)
          builder = RepoArtifactBuilder.new(@config_dir, repo, @store)

          run_with_lock(repo.lock_file) {
            @log.debug "clone repo"
            repo.clone
            @log.debug "update repo"
            repo.update
            result = builder.build_and_move_to_store(
              cmd,
              artifact,
              force: force)
            @log.debug("build result: #{result}")

            result
          }
        end
      end
    end
  end
end
