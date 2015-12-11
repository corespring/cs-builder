require 'thor'

Dir[File.dirname(__FILE__) + '/cmds/*.rb'].each {|file| require file }

require_relative './log/logger'

module OptsHelper 

  def inner_merge(hashes, acc)
    if(hashes.length == 0)
      acc
    else 
      acc = acc.merge(hashes.shift)
      inner_merge(hashes, acc)
    end
  end

  def merge(*hashes)
    inner_merge(hashes, {})
  end

  def add_opts(scope, *opts)
    merged = merge(*opts)
    merged.each{ |k,v| 
      scope[k] = Thor::Option.new(k, v)
    }
  end

  def str(d: "", r:false, f: nil)
    {:type => :string, :required => r, :desc => d, :default => f}
  end

  def org_repo(required, override: false)
    { 
      :org => str(r: required, d: "#{override ? "override " : ""}the org"),
      :repo => str(r: required, d: "#{override ? "override " : ""}the repo")
    } 
  end
end

module CsBuilder

  module Docs
    def self.docs(name)
      here = File.dirname(__FILE__)
      ::IO.read(File.join(here, "..", "..", "docs", "#{name}.md"))
    end
  end

  include Commands

  class CLI < Thor

    extend OptsHelper 
    
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
      cmd = Commands::Artifacts::DeployFromBranch.new(options[:config_dir])
      puts "todo..."
    end  

    desc "artifact-deploy-from-tag", "Looks for an artifact with the given tag, slugifys it, deploys it."
    add_opts(options, heroku, platform, org_repo(true))
    option :force, force
    option :tag, str(r:true, d: "The tag/version to look for")
    def artifact_deploy_from_tag
    end

    desc "artifact-deploy-from-file", "deploy from an artifact file"
    add_opts(options, heroku, platform)
    option :force, force
    option :artifact_file, str(r:true)
    option :tag, str(r:true) 
    option :sha, str
    def artifact_deploy_from_file
    end

    desc "slug-mk-from-artifact-file", "create a heroku slug from an artifact"
    add_opts(options, platform)
    option :artifact_file, str(r:true, d: "The path to the artifact")
    option :out_path, str(r:true, d: "Where to save the slug")
    option :force, force 
    def slug_mk_from_artifact_file
      CsBuilder::Log.load_config(options[:log_config])
      cmd = Commands::MakeSlugFromArtifact.new(options[:config_dir])
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
      cmd = Commands::DeploySlugFile.new(options[:config_dir], options[:stack])
      out = cmd.run(options)
      puts "deployed to: #{options[:app]}"
    end

    # desc "build-from-git", "clone if needed, update, build and create an archive"
    # git_opts.each{|k,v| option(k,v)}
    # option :build_assets, :type => :array, :required => false
    # option :cmd, :type => :string, :default => "play clean update compile stage"
    # option :force, :type => :boolean, :default => false
    # long_desc Docs.docs("build-from-git")
    # def build_from_git
    #   CsBuilder::Log.load_config(options[:log_config])
    #   cmd = Commands::BuildFromGit.new(options[:config_dir])
    #   out = cmd.run(options)
    #   puts out
    # end

    # desc "build-from-file", "copy a local project, build and create an archive"
    # option :external_src, :type => :string, :required => true
    # option :org, :type => :string, :required => true
    # option :repo, :type => :string, :required => true
    # option :branch, :type => :string, :required => true
    # option :build_assets, :type => :array, :required => true
    # option :cmd, :type => :string, :default => ""
    # option :uid, :type => :string, :required => true
    # option :force, :type => :boolean, :default => false
    # long_desc Docs.docs("build-from-file")
    # def build_from_file
    #   CsBuilder::Log.load_config(options[:log_config])
    #   cmd = Commands::BuildFromFile.new(options[:config_dir])
    #   out = cmd.run(options)
    #   puts out
    # end

    # desc "file-slug", "make a slug from a binary"
    # option :branch, :type => :string, :required => true
    # option :uid, :type => :string, :required => true
    # option :org, :type => :string, :required => true
    # option :repo, :type => :string, :required => true
    # option :template, :type => :string, :default => "jdk-1.7"
    # option :force, :type => :boolean, :default => false
    # long_desc Docs.docs("file-slug")
    # def file_slug
    #   CsBuilder::Log.load_config(options[:log_config])
    #   cmd = Commands::MakeFileSlug.new(options[:config_dir])
    #   out = cmd.run(options)
    #   puts "Done: #{out}"
    # end


    # desc "remove-config", "remove ~/.cs-build config folder (Can't undo!!)"
    # def remove_config
    #   CsBuilder::Log.load_config(options[:log_config])
    #   Commands::RemoveConfig.new(options[:config_dir]).run
    # end

    # desc "git-slug", "make a slug"
    # git_opts.each{|k,v| option(k,v)}
    # option :sha, :type => :string, :required => false
    # option :template, :type => :string, :default => "jdk-1.7"
    # option :force, :type => :boolean, :default => false
    # long_desc Docs.docs("git-slug")
    # def git_slug
    #   CsBuilder::Log.load_config(options[:log_config])
    #   cmd = Commands::MakeGitSlug.new(options[:config_dir])
    #   out = cmd.run(options)

    #   puts "Done: #{out}"
    # end

    # desc "list-slugs", "list all slugs"
    # def list_slugs
    #   CsBuilder::Log.load_config(options[:log_config])
    #   cmd = Commands::ListSlugs.new(options[:config_dir])
    #   cmd.run(options)
    # end

    # desc "remove template", "remove template"
    # option :template, :type => :string, :required => true
    # def remove_template
    #   CsBuilder::Log.load_config(options[:log_config])
    #   cmd = Commands::RemoveTemplate.new(options[:config_dir])
    #   cmd.run(options)
    # end

    # desc "heroku-deploy-slug", "deploy a slug"
    # git_opts.each{|k,v| option(k,v)}
    # option :git, :type => :string, :required => true
    # option :branch, :type => :string, :required => true
    # option :heroku_app, :type => :string, :required => true
    # option :commit_hash, :type => :string
    # option :stack, :type => :string, :default => "cedar-14"
    # def heroku_deploy_slug
    #   CsBuilder::Log.load_config(options[:log_config])
    #   cmd = Commands::HerokuDeploySlug.new(options[:config_dir], options[:stack])
    #   puts cmd.run(options)
    # end

  end
end
