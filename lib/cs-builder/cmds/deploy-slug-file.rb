require_relative '../git/git-parser'
require_relative '../git/git-helper'
require_relative '../heroku/heroku-deployer'
require_relative '../heroku/slug-helper'
require_relative '../models/paths'
require_relative '../in-out/file-lock'
require_relative 'core-command'

require 'yaml'

module CsBuilder
  module Commands

    class  DeploySlugFile < CoreCommand

      include Models
      include Git
      include Heroku
      include Heroku::SlugHelper
      include IO::FileLock

      def initialize(config_dir, stack)
        @stack = stack
        super('deploy-slug-file', config_dir)
      end

      def run(options)
        deployer = HerokuDeployer.new
        app = options[:app]
        slug = options[:slug]
        sha = options[:version]
        description = options[:description]

        @log.debug "slug: #{slug}, sha: #{sha}, description: #{description}, stack: #{@stack}"
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

