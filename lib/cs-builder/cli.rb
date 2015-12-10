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
      :git => {:type => :string, :required => true},
      :branch => {:type => :string, :required => true}
    }
    
    desc "make-artifact-git", "clone if needed, update, run command that creates an archive"
    git_opts.each{|k,v| option(k,v)}
    option :artifact, :type => :string, :required => true
    option :cmd, :type => :string, :default => "play dist"
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("make-artifact-git")
    def make_artifact_git
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::MakeArtifactGit.new(options[:config_dir])
      out = cmd.run(options)
      puts out
    end
    
    desc "deploy-artifact", "deploys an artifact to heroku"
    git_opts.each{|k,v| option(k,v)}
    option :version, :type => :string, :required => false 
    option :artifact_format, :type => :string, :required => true 
    option :app, :type => :string, :required => false 
    option :force, :type => :boolean, :default => false
    long_desc Docs.docs("deploy-artifact")
    def deploy_artifact
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::DeployArtifact.new(options[:config_dir])
      out = cmd.run(options)
      puts out
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
