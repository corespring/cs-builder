require 'thor'

Dir[File.dirname(__FILE__) + '/cmds/*.rb'].each {|file| require file }

require_relative './log/logger'

module CsBuilder

  module Docs
    def self.docs(name)
      here = File.dirname(__FILE__)
      ::IO.read(File.join(here, "..", "..", "docs", "#{name}.md"))
    end
  end

  include Commands

  class CLI < Thor

    class_option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    class_option :log_config, :type => :string, :default => File.expand_path("~/.cs-builder/log-config.yml") 

    include CsBuilder::Docs

    
    git_opts = {
      :git => {:type => :string, :required => true, :desc => "the git repo to clone (eg: git@github.com:org/repo.git) (note: url is used to create :org and :repo)"},
      :branch => {:type => :string, :required => true, :desc => "the branch of the git repo to checkout (eg: master)"}
    }
   
    desc "make-artifact-git", "create an artifact from a git repo and branch"
    git_opts.each{|k,v| option(k,v)}
    option :org, :type => :string, :desc => "override the org (derived from --git)"
    option :repo, :type => :string, :desc => "override the repo (derived from --git)"
    option :cmd, :type => :string, :required => true, :desc => "this command is run against the project and it must create a .tgz of your project"
    option :artifact, :type => :string, :required => true, :desc => "a regex pattern to find the artifact and derive the :version (eg: dist/my-app-(.*).tgz)"
    option :version, :type => :string, :desc => "override the version derived from the regex group in --artifact"
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("make-artifact-git")
    def make_artifact_git
      CsBuilder::Log.load_config(options[:log_config])
      puts "TODO..."
      #cmd = Commands::MakeArtifactGit.new(options[:config_dir])
      #out = cmd.run(options)
      #puts out
    end

    desc "make-artifact", "create an artifact from a directory and place it in the artifacts directory"
    option :dir, :type => :string, :required => true, :desc => "The path to the project where the --cmd will be run"
    option :org, :type => :string, :required => true 
    option :repo, :type => :string, :required => true 
    option :cmd, :type => :string, :required => true, :desc => "this command is run against the project and it must create a .tgz of your project"
    option :artifact, :type => :string, :required => true, :desc => "a regex pattern to find the artifact and derive the :version (eg: dist/my-app-(.*).tgz)"
    option :version, :type => :string, :desc => "override the version derived from the regex group in --artifact"
    option :force, :type => :boolean, :default => false
    def make_artifact
      puts "TODO"
    end

    desc "make-slug-from-artifact", "create a heroku slug from an artifact"
    option :artifact, :type => :string, :required => true, :desc => "The path to the artifact"
    option :platform, :type => :string, :required => true, :desc => "The platform to use (jdk-1.7, jdk-1.8, ...)"
    option :out, :type => :string, :required => true, :desc => "Where to save the slug"
    option :force, :type => :boolean, :default => false
    def make_slug_from_artifact
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::MakeSlugFromArtifact.new(options[:config_dir])
      out = cmd.run(options)
      puts "done."
    end
    
    desc "deploy-slug-file", "create a heroku slug from an artifact"
    option :slug, :type => :string, :required => true, :desc => "The path to the slug"
    option :stack, :type => :string, :default => "cedar-14", :desc => "The heroku stack to use"
    option :app, :type => :string, :required => true, :desc => "The heroku app name"
    option :version, :type => :string, :desc => "The version of the slug (typically a git tag or commit hash)"
    option :description, :type => :string, :desc => "A description", :default => "deploy"
    option :force, :type => :boolean, :default => false
    def deploy_slug_file
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::DeploySlugFile.new(options[:config_dir], options[:stack])
      out = cmd.run(options)
      puts "deployed to: #{options[:app]}"
    end

    desc "build-from-git", "clone if needed, update, build and create an archive"
    git_opts.each{|k,v| option(k,v)}
    option :build_assets, :type => :array, :required => false
    option :cmd, :type => :string, :default => "play clean update compile stage"
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("build-from-git")
    def build_from_git
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::BuildFromGit.new(options[:config_dir])
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
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("build-from-file")
    def build_from_file
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::BuildFromFile.new(options[:config_dir])
      out = cmd.run(options)
      puts out
    end

    desc "file-slug", "make a slug from a binary"
    option :branch, :type => :string, :required => true
    option :uid, :type => :string, :required => true
    option :org, :type => :string, :required => true
    option :repo, :type => :string, :required => true
    option :template, :type => :string, :default => "jdk-1.7"
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("file-slug")
    def file_slug
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::MakeFileSlug.new(options[:config_dir])
      out = cmd.run(options)
      puts "Done: #{out}"
    end


    desc "remove-config", "remove ~/.cs-build config folder (Can't undo!!)"
    def remove_config
      CsBuilder::Log.load_config(options[:log_config])
      Commands::RemoveConfig.new(options[:config_dir]).run
    end

    desc "git-slug", "make a slug"
    git_opts.each{|k,v| option(k,v)}
    option :sha, :type => :string, :required => false
    option :template, :type => :string, :default => "jdk-1.7"
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("git-slug")
    def git_slug
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::MakeGitSlug.new(options[:config_dir])
      out = cmd.run(options)

      puts "Done: #{out}"
    end

    desc "list-slugs", "list all slugs"
    def list_slugs
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::ListSlugs.new(options[:config_dir])
      cmd.run(options)
    end

    desc "remove template", "remove template"
    option :template, :type => :string, :required => true
    def remove_template
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::RemoveTemplate.new(options[:config_dir])
      cmd.run(options)
    end

    desc "heroku-deploy-slug", "deploy a slug"
    git_opts.each{|k,v| option(k,v)}
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :heroku_app, :type => :string, :required => true
    option :commit_hash, :type => :string
    option :stack, :type => :string, :default => "cedar-14"
    def heroku_deploy_slug
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::HerokuDeploySlug.new(options[:config_dir], options[:stack])
      puts cmd.run(options)
    end

  end
end
