require_relative 'core-command'
require_relative '../models/paths'
require_relative '../git/git-parser'


include CsBuilder::Git 

module CsBuilder
  module Cmds
    class BuildFromGit < CoreCommand

      def initialize(config_dir)
        super('build-from-git', config_dir)
      end

      def run(git_url:, branch:, cmd:, org: nil, repo_name: nil)
        org = org.nil? ? GitUrlParser.org(git_url) : org 
        repo_name = repo_name.nil? ? GitUrlParser.org(git_url) :  repo_name 
        @paths = Paths.new(@config_dir, org, repo_name, branch)
        run_with_lock(@paths.lock_file("build")) {
          in_dir(@paths.repo){
            @log.debug( "run: #{cmd}")
            run_cmd cmd 
          }
        }
      end
    end
  end
end