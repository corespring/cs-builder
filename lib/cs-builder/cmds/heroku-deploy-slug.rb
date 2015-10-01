require_relative '../git/git-parser'
require_relative '../git/git-helper'
require_relative '../heroku/heroku-deployer'
require_relative '../heroku/slug-helper'
require_relative '../models/paths'
require_relative '../io/file-lock'
require_relative '../io/safe-file-removal'

require 'yaml'

module CsBuilder
  module Commands

    class HerokuDeploySlug < CoreCommand

      include Models
      include Git
      include Heroku
      include Git::GitHelper
      include Heroku::SlugHelper
      include Io::FileLock
      include Io::SafeFileRemoval      

      def initialize(level, config_dir, stack, clean_up)
        @stack = stack
        @clean_up = clean_up
        super('heroku_deploy_slug', level, config_dir)
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
        slug = File.join(paths.slugs, "#{sha}.tgz")
        @log.debug "slug -> #{slug}"
        @log.debug "STACK -> #{@stack}"
        raise "Can't find slug to deploy #{slug}" unless File.exists? slug
        with_file_lock(slug){
          deployer.deploy(slug, SlugHelper.processes_from_slug(slug), app, sha, @stack)
          
          cleanup(@clean_up, paths)
        }

      end

      def cleanup(clean_up, paths)
        safely_remove(paths.repo) if clean_up
        safely_remove(paths.slugs) if clean_up
      end

    end
  end
end
