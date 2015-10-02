require 'thor'

Dir[File.dirname(__FILE__) + '/cmds/*.rb'].each {|file| require file }

module CsBuilder

  module Docs
    def self.docs(name)
      here = File.dirname(__FILE__)
      IO.read(File.join(here, "..", "..", "docs", "#{name}.md"))
    end
  end


  include Commands

  class CLI < Thor

    include CsBuilder::Docs

    desc "build-from-git", "clone if needed, update, build and create an archive"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :build_assets, :type => :array, :required => false
    option :cmd, :type => :string, :default => "play clean update compile stage"
    option :log_level, :type => :string, :default => "INFO"
    option :force, :type => :boolean, :default => false
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    long_desc Docs.docs("build-from-git")
    def build_from_git
      puts options
      cmd = Commands::BuildFromGit.new(options[:log_level], options[:config_dir])
      out = cmd.run(options)
      puts out
    end

    desc "build-from-file", "copy a local project, build and create an archive"
    option :external_src, :type => :string, :required => true
    option :org, :type => :string, :required => true
    option :repo, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :build_assets, :type => :array, :required => true
    option :cmd, :type => :string, :default => ""
    option :uid, :type => :string, :required => true
    option :log_level, :type => :string, :default => "INFO"
    option :force, :type => :boolean, :default => false
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    long_desc Docs.docs("build-from-file")
    def build_from_file
      puts options
      cmd = Commands::BuildFromFile.new(options[:log_level], options[:config_dir])
      out = cmd.run(options)
      puts out
    end

    desc "file-slug", "make a slug from a binary"
    option :branch, :type => :string, :required => true
    option :uid, :type => :string, :required => true
    option :org, :type => :string, :required => true
    option :repo, :type => :string, :required => true
    option :template, :type => :string, :default => "jdk-1.7"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("file-slug")
    def file_slug
      cmd = Commands::MakeFileSlug.new(options[:log_level], options[:config_dir])
      out = cmd.run(options)
      puts "Done: #{out}"
    end


    desc "remove-config", "remove ~/.cs-build config folder (Can't undo!!)"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def remove_config
      Commands::RemoveConfig.new(options[:config_dir]).run
    end

    desc "git-slug", "make a slug"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :sha, :type => :string, :required => false
    option :template, :type => :string, :default => "jdk-1.7"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("git-slug")
    def git_slug
      cmd = Commands::MakeGitSlug.new(options[:log_level], options[:config_dir])
      out = cmd.run(options)

      puts "Done: #{out}"
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
    option :heroku_app, :type => :string, :required => true
    option :commit_hash, :type => :string
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    option :stack, :type => :string, :default => "cedar-14"
    option :clean_up, :type => :boolean, :default => false
    long_desc Docs.docs("deploy-slug")
    def heroku_deploy_slug
      cmd = Commands::HerokuDeploySlug.new(options[:log_level], options[:config_dir], options[:stack], options[:clean_up])
      puts cmd.run(options)
    end

    desc "clean-repos", "clean old / unused repos and slugs"
    option :older_than_days, :type => :numeric, :default => 7
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    long_desc Docs.docs("clean-repos")
    def clean_repos
      cmd = Commands::CleanRepos.new(options[:log_level], options[:config_dir], options[:older_than_days])
      puts cmd.run(options)
    end

  end
end
