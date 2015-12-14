require_relative '../../log/logger'
require_relative '../../git/git-parser'
require_relative '../../git/repo'
require_relative '../../artifacts/repo-artifacts'
require_relative '../../init'

module CsBuilder
  module Commands
    module Artifacts
      class List

        include CsBuilder::Git
        include CsBuilder::Artifacts

        def initialize(config_dir)
          CsBuilder::Init.init_cs_builder_dir(config_dir)
          @config_dir = config_dir
          @log = CsBuilder::Log.get_logger("list")
        end
        
        def run(options)
          @log.debug("options: #{options}")
          git_url = options[:git]
          org = options.has_key?(:org) ? options[:org] : GitUrlParser.org(git_url)
          repo = options.has_key?(:repo) ? options[:repo] : GitUrlParser.repo(git_url)
          @paths = Paths.new(@config_dir, org, repo, "branch")
          @repo = Repo.new(@config_dir, git_url, org, repo, options[:branch])
          @artifacts = RepoArtifacts.new(@config_dir, @repo)
          Dir["#{@paths.artifacts}/**/*.tgz"]
        end
      end
    end
  end
end
