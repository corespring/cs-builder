require 'thor'

Dir[File.dirname(__FILE__) + '/cmds/*.rb'].each {|file| require file }

module CsBuilder

  include Commands

  class CLI < Thor

    desc "build-from-git", "checkout (if needed) and build"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :binaries, :type => :array, :required => true
    option :cmd, :type => :string, :default => "play clean update compile stage"
    option :log_level, :type => :string, :default => "INFO"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def build_from_git
      puts options
      cmd = Commands::BuildFromGit.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end


=begin
    desc "build-from-folder", "checkout (if needed) and build"
    option :path, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :org, :type => :string, :required => true
    option :binaries, :type => :array, :required => true
    option :cmd, :type => :string, :default => "play clean update compile stage"
    option :log_level, :type => :string, :default => "INFO"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def build_from_folder
      puts options
      cmd = Commands::BuildFromFile.new(options[:log_level], options[:config_dir])
      puts cmd.run(options)
    end
=end
    desc "remove-config", "remove ~/.cs-build config folder (Can't undo!!)"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def remove_config
      Commands::RemoveConfig.new(options[:config_dir]).run
    end


    desc "slug", "make a slug"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :sha, :type => :string, :required => false
    option :template, :type => :string, :default => "jdk-1.7"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def slug
      cmd = Commands::MakeSlug.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end

    desc "list-slugs", "list all slugs"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :sha, :type => :string, :required => false
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def list_slugs
      cmd = Commands::ListSlugs.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end

    desc "remove template", "remove template"
    option :template, :type => :string, :required => true
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def remove_template 
      cmd = Commands::RemoveTemplate.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end

    desc "list templates", "list installed templates"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def list_templates
      cmd = Commands::ListTemplates.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end

    desc "heroku-deploy-slug", "deploy a slug"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :commit_hash, :type => :string 
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def deploy_slug
      cmd = Commands::HerokuDeploySlug.new
      puts cmd.run(options)
    end



=begin
    desc "list-slugs", "list slugs for git+branch"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def list_slugs
      cmd = Commands::ListSlugs.new
      puts cmd.run(options)
    end

    desc "slug-templates", "list slug templates"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def slug_templates 
      cmd = Commands::SlugTemplates.new
      puts cmd.run(options)
    end
=end
  end
end
