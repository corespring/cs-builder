require 'thor'

Dir[File.dirname(__FILE__) + '/cmds/**/*.rb'].each {|file| require file }

require_relative './log/logger'
require_relative './opts-helper'

module CsBuilder

  module Docs
    def self.docs(name)
      here = File.dirname(__FILE__)
      ::IO.read(File.join(here, "..", "..", "docs", "#{name}.md"))
    end
  end


  class CLI < Thor

    extend OptsHelper 
    
    include CsBuilder::Commands

    class_option :config_dir, str(f: File.expand_path("~/.cs-builder"))
    class_option :log_config, str(f: File.expand_path("~/.cs-builder/log-config.yml"))

    include CsBuilder::Docs
  
    git = { 
      :git => str(r:true, d: "the git repo (eg: git@github.com:org/repo.git) (note: url is used to create :org and :repo)"),
      :branch => str(r:true, d: "the git branch (eg: master)")
    }
   
    heroku = {
      :heroku_app => str(r:true),
      :heroku_stack => str(r:true, f: "cedar-14")
    }

    platform = { 
     :platform => str(d: "The platform to use (jdk-1.7, jdk-1.8, ...)", r: true)
    }

    force = {:type => :boolean, :default => false}

    desc "artifact-mk-from-git", "create an artifact from a git repo and branch and store it for later use"
    add_opts(options, git, org_repo(false, override:true))
    option :cmd, str(r:true, d: "this command is run against the project and it must create a .tgz of your project")
    option :artifact_pattern, str(r:true, d: "a regex pattern to find the artifact and derive the :tag (eg: dist/my-app-(.*).tgz)")
    option :tag, str(d: "override the version derived from the regex group in --artifact")
    option :force, force 
    long_desc Docs.docs("make-artifact-git")
    def artifact_mk_from_git
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::Artifacts::MkFromGit.new(options[:config_dir])
      out = cmd.run(options)
      puts out
    end
   
    desc "artifact-deploy-from-branch", "Gets the sha/tag from the head of the repo branch, looks for the artifact, slugs it, deploys it"
    add_opts(options, git, heroku, platform, org_repo(false, override:true))
    option :force, :type => :boolean, :default => false
    def artifact_deploy_from_branch
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Artifacts::DeployFromBranch.new(options[:config_dir])
      cmd.run(options)
    end  

    desc "artifact-deploy-from-tag", "Looks for an artifact with the given tag, slugifies it, deploys it."
    add_opts(options, heroku, platform, org_repo(true))
    option :force, force
    option :tag, str(r:true, d: "The tag/version to look for")
    def artifact_deploy_from_tag
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Artifacts::DeployFromTag.new(options[:config_dir])
      cmd.run(options)
    end

    desc "artifact-deploy-from-file", "deploy from an artifact file"
    add_opts(options, heroku, platform)
    option :force, force
    option :artifact_file, str(r:true)
    option :tag, str(r:true) 
    option :hash, str
    def artifact_deploy_from_file
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Artifacts::DeployFromFile.new(options[:config_dir])
      cmd.run(options)
    end

    desc "artifact-list", "list available artifacts"
    add_opts(options, git, org_repo(false))
    def artifact_list
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Artifacts::List.new(options[:config_dir])
      list = cmd.run(options)
      puts list.join("\n")
    end

    desc "slug-mk-from-artifact-file", "create a heroku slug from an artifact"
    add_opts(options, platform)
    option :artifact_file, str(r:true, d: "The path to the artifact")
    option :out_path, str(r:true, d: "Where to save the slug")
    option :force, force 
    def slug_mk_from_artifact_file
      CsBuilder::Log.load_config(options[:log_config])
      cmd = MakeSlugFromArtifact.new(options[:config_dir])
      out = cmd.run(options)
      puts "done."
    end

    desc "slug-deploy-from-file", "create a heroku slug from an artifact"
    add_opts(options, heroku)
    option :slug_file, str(r:true, d: "The path to the slug")
    option :tag, str(d: "The version of the slug (typically a git tag or commit hash)")
    option :description, str(d: "A description", f: "deploy")
    option :force, force 
    def slug_deploy_from_file
      CsBuilder::Log.load_config(options[:log_config])
      cmd = DeploySlugFile.new(options[:config_dir], options[:stack])
      out = cmd.run(options)
      puts "deployed to: #{options[:app]}"
    end

  end
end
