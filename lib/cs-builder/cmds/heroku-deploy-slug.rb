require_relative '../git-parser' 
require_relative '../heroku-deployer'
require_relative '../models'

require 'yaml' 


module CsBuilder
  module Commands

    class HerokuDeploySlug < CoreCommand

      include Models
      include Models::GitHelper

      def initialize(level, config_dir)
        super('heroku_deploy_slug', level, config_dir)
      end

      def run(options)
        deployer = HerokuDeployer.new
        app = options[:heroku_app]
        git = options[:git]
        org =  GitParser.org(git)
        repo = GitParser.repo(git)
        branch = options[:branch]

        paths = Paths.new(@config_dir, org, repo, branch)
        sha = commit_hash(paths.repo)

        slug = File.join(paths.slugs, "#{sha}.tgz")
        @log.debug "slug -> #{slug}"

        raise "Can't find slug to deploy #{slug}" unless File.exists? slug

        deployer.deploy(slug, processes_from_slug(slug), app)
      end

      private 
      def processes_from_slug(slug)
        `tar -zxvf #{slug} ./app/Procfile`
        proc_yml = YAML.load_file('./app/Procfile')
        FileUtils.rm_rf 'app/Procfile'
        proc_yml
      end
    end
  end
end