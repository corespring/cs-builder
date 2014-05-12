require_relative '../git/git-parser'
require_relative '../heroku/heroku-deployer'
require_relative '../models/paths'

require 'yaml'


module CsBuilder
  module Commands

    class HerokuDeploySlug < CoreCommand

      include Models
      include Models::GitHelper
      include Models::SlugHelper

      def initialize(level, config_dir)
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

        raise "Can't find slug to deploy #{slug}" unless File.exists? slug

        deployer.deploy(slug, SlugHelper.processes_from_slug(slug), app)
      end

    end
  end
end
