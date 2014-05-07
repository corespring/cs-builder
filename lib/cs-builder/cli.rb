require 'thor'

require 'cs-builder/cmds'

module CsBuilder

  include Commands

  class CLI < Thor

    desc "build", "checkout (if needed) and build"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :cmd, :type => :string, :default => "clean update compile stage"
    option :log_level, :type => :string, :default => "INFO"
    def build
      puts options
      cmd = Commands::Build.new(options[:log_level])
      #puts cmd.run(options)
    end

    desc "slug", "make a slug"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :template, :type => :string, :default => "jdk-1.7"
    def slug
      cmd = Commands::Slug.new
      puts cmd.run(options)
    end

    desc "heroku-deploy-slug", "deploy a slug"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :commit_hash, :type => :string 
    def deploy_slug
      cmd = Commands::DeploySlug.new
      puts cmd.run(options)
    end

    desc "list-slugs", "list slugs for git+branch"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    def list_slugs
      cmd = Commands::ListSlugs.new
      puts cmd.run(options)
    end

    desc "slug-templates", "list slug templates"
    def slug_templates 
      cmd = Commands::SlugTemplates.new
      puts cmd.run(options)
    end
  end
end
