require_relative '../git-parser' 
require_relative '../heroku-deployer'
require_relative '../models'

require 'yaml' 


module CsBuilder
  module Commands

    class HerokuDeploySlug < CoreCommand

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

        paths = Paths.new(org, repo, branch)
        sha = get_sha(org, repo, options[:branch])
        slug = slug_path(org, repo, branch, sha, suffix: ".tgz")

        raise "Can't find slug to deploy #{slug}" unless File.exists? slug

        `tar -zxvf #{slug} ./app/Procfile`
        proc_yml = YAML.load_file('./app/Procfile')
        deployer.deploy(slug, proc_yml, app)
        FileUtils.rm_rf 'app/Procfile'
      end
    end
  end
end