require_relative '../git/git-parser'
require_relative '../git/git-helper'
require_relative '../heroku/heroku-deployer'
require_relative '../heroku/slug-helper'
require_relative '../models/paths'
require_relative '../io/file-lock'
require_relative 'core-command'

require 'yaml'

module CsBuilder
  module Commands

    class HerokuDeploySlug < CoreCommand

      include Models
      include Git
      include Heroku
      include Git::GitHelper
      include Heroku::SlugHelper
      include IO::FileLock

      def initialize(config_dir, stack)
	      @stack = stack
        super('heroku_deploy_slug', config_dir)
      end

      def run(options)
        deployer = HerokuDeployer.new
        app = options[:heroku_app]
        git = options[:git]
        org =  GitUrlParser.org(git)
        repo = GitUrlParser.repo(git)
        branch = options[:branch]

        paths = Paths.new(@config_dir, org, repo, branch)
        sha = commit_hash(paths.repo)
        uid = git_uid(paths.repo) # tag with fallback to sha
        description = commit_tag(paths.repo) or "no tag"
        slug = File.join(paths.slugs, "#{uid}.tgz")
        @log.debug "slug: #{slug}, uid: #{uid}, sha: #{sha}, description: #{description}, stack: #{@stack}"
        raise "Can't find slug to deploy #{slug}" unless File.exists? slug

        with_file_lock(slug){
          deployer.deploy(
            slug, 
            SlugHelper.processes_from_slug(slug), 
            app, 
            sha, 
            description, 
            @stack,
            force: options[:force])
        }
      end

    end
  end
end
