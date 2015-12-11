require_relative '../log/logger'
require_relative '../git/git-parser'
require_relative '../git/repo'
require_relative '../runner'
require_relative '../artifacts/repo-artifacts'
require_relative '../init'


module CsBuilder
  module Commands

    class MakeArtifactGit

      include CsBuilder::Runner
      include CsBuilder::Git
      include CsBuilder::Artifacts

      def initialize(config_dir)
        CsBuilder::Init.init_cs_builder_dir(config_dir)
        @config_dir = config_dir
        @log = CsBuilder::Log.get_logger("make-artifact-git")
      end
      
      def run(options)

        @log.debug("options: #{options}")

        git_url = options[:git]

        org = options.has_key?(:org) ? options[:org] : GitUrlParser.org(git_url)
        repo = options.has_key?(:repo) ? options[:repo] : GitUrlParser.repo(git_url)

        @repo = Repo.new(@config_dir, git_url, org, repo, options[:branch])
        @artifacts = RepoArtifacts.new(@config_dir, @repo, options[:cmd], options[:artifact])

        run_with_lock(@repo.lock_file) {
          @log.debug "clone repo"
          @repo.clone
          @log.debug "update repo"
          @repo.update
          force = options[:force] == true
          result = @artifacts.build_and_move_to_store(force: force)
          @log.debug("build result: #{result}")
          result
        }
      end
    end
  end
end
