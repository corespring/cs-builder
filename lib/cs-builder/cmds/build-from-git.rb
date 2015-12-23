require_relative 'core-command'
require_relative '../models/paths'
require_relative '../git/repo'
require_relative '../runner'
require_relative '../git/git-parser'


include CsBuilder::Git 

module CsBuilder
  module Commands
    class BuildFromGit < CoreCommand

      include CsBuilder::Runner
      
      def initialize(config_dir)
        super('build-from-git', config_dir)
      end

      def run(git_url:, branch:, cmd:, org: nil, repo_name: nil)
        org = nil_or_empty?(org) ? GitUrlParser.org(git_url) : org 
        repo_name = nil_or_empty?(repo_name) ? GitUrlParser.org(git_url) : repo_name 
        @paths = Paths.new(@config_dir, org, repo_name, branch)
        repo = Repo.new(@config_dir, git_url, org, repo_name, branch)
        repo.clone_and_update

        run_with_lock(@paths.lock_file("build")) {
          in_dir(@paths.repo){
            @log.debug( "run: #{cmd}")
            run_cmd cmd 
          }
        }
      end

      def nil_or_empty?(s)
        s.nil? or s.empty?
      end

    end
  end
end