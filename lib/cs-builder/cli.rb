require 'thor'

Dir[File.dirname(__FILE__) + '/cmds/**/*.rb'].each {|file| require file }

require_relative './log/logger'
require_relative './opts-helper'
require 'cs-builder/artifacts/store/remote-and-local-store'

include CsBuilder::Log
include CsBuilder::Commands
include CsBuilder::Commands::Artifacts
include CsBuilder::Artifacts

module CsBuilder

  module Docs
    def self.docs(name)
      here = File.dirname(__FILE__)
      ::IO.read(File.join(here, "..", "..", "docs", "#{name}.md"))
    end
  end


  class CLI < Thor

    def self.exit_on_failure?
      true
    end

    extend OptsHelper 


    @@log = CsBuilder::Log.get_logger('CLI')

    
    class_option :config_dir, str(f: File.expand_path("~/.cs-builder"))
    class_option :log_config, str(f: File.expand_path("~/.cs-builder/log-config.yml"))

    include CsBuilder::Docs
    

    git = { 
      :git => str(r:true, d: "the git repo (eg: git@github.com:org/repo.git) (note: url is used to create :org and :repo)"),
      :branch => str(r:true, d: "the git branch (eg: master)")
    }
   
    heroku = {
      :heroku_app => str(r:true),
      :heroku_stack => str(r:true, f: "cedar-14"),
      :procfile => str(f: "Procfile", d: "The path to the Procfile")
    }

    platform = { 
     :platform => str(d: "The platform to use (jdk-1.7, jdk-1.8, ...)", r: true)
    }

    force = {:type => :boolean, :default => false}
    
    no_commands{
      def get_store(root_dir)
        RemoteAndLocalStore.build(File.join(root_dir, "artifacts"))
      end

      def to_deploy_opts(opts, *keys)
        opts.select{ |k| keys.include?(k) }
      end

      def prep(name, options) 
        o = OptsHelper.symbols(options)
        Log.load_config(o[:log_config])
        @@log.info("running: #{name}: options: #{o}")
        yield o
      end
    } 

    #TODO: RM locks

    desc "build-from-git", "just run a command against a repo"
    add_opts(options, git, org_repo(false, override:true))
    option :cmd, str(r:true)
    def build_from_git 
      prep(__method__, options){ |o|
        cmd = BuildFromGit.new(o[:config_dir])
        out = cmd.run(
          git_url: o[:git],
          branch: o[:branch],
          cmd: o[:cmd],
          org: o[:org],
          repo_name: o[:repo])

        puts out
      }
    end

    desc "artifact-mk-from-git", "create an artifact from a git repo and branch and store it for later use"
    add_opts(options, git, org_repo(false, override:true))
    option :cmd, str(r:true, d: "this command is run against the project and it must create a .tgz of your project")
    option :artifact, str(r:true, d: "a regex pattern to find the artifact and derive the :tag (eg: dist/my-app-(.*).tgz)")
    option :tag, str(d: "override the version derived from the regex group in --artifact")
    option :force, force 
    option :back_up_if_tagged, :type => :boolean, :default => true
    long_desc Docs.docs("make-artifact-git")
    def artifact_mk_from_git
      prep(__method__, options){|o|
        cmd = MkFromGit.new(o[:config_dir], get_store(o[:config_dir]))
        out = cmd.run(
          git_url: o[:git],
          branch: o[:branch],
          cmd: o[:cmd],
          artifact: o[:artifact], 
          org: o[:org],
          repo_name: o[:repo],
          force: o[:force])

        puts out
      }
    end
   
    desc "artifact-deploy-from-branch", "Gets the sha/tag from the head of the repo branch, looks for the artifact, slugs it, deploys it"
    add_opts(options, git, heroku, platform, org_repo(false, override:true))
    option :force, :type => :boolean, :default => false
    def artifact_deploy_from_branch
      prep(__method__, options){|o|
        cmd = DeployFromBranch.build(
          o[:config_dir], 
          get_store(o[:config_dir]),
          git_url: o[:git],
          branch: o[:branch],
          org: o.has_key?(:org) ? o[:org] : nil,
          repo_name: o.has_key?(:repo) ? o[:repo] : nil)

        deploy_opts = to_deploy_opts(o, :heroku_app, :heroku_stack, :procfile, :platform, :force) 
        @@log.info("[deploy-from-branch]: deploy_opts: #{deploy_opts}")
        out = cmd.run(deploy_opts)
        puts out
      }
    end  

    desc "artifact-deploy-from-tag", "Looks for an artifact with the given tag, slugifies it, deploys it."
    add_opts(options, heroku, platform, git, org_repo(false, override:true))
    option :force, force
    option :tag, str(r:true, d: "The tag/version to look for")
    def artifact_deploy_from_tag
      prep(__method__, options){ |o|
        cmd = DeployFromTag.build(
          o[:config_dir], 
          get_store(o[:config_dir]), 
          o[:tag],
          git_url: o[:git],
          org: o[:org],
          repo_name: o[:repo])
        deploy_opts = to_deploy_opts(o, :heroku_app, :heroku_stack, :procfile, :platform, :force) 
        @@log.info("[deploy-from-tag]: deploy_opts: #{deploy_opts}")
        cmd.run(deploy_opts)
      }
    end

    
    desc "artifact-deploy-from-file", "slugifies the file and deploys it."
    add_opts(options, heroku, platform)
    option :force, force
    option :artifact_file, str(r:true)
    option :tag, str(r:true) 
    option :hash, str
    def artifact_deploy_from_file
      prep(__method__, options) { |o| 
        cmd = DeployFromFile.new(o[:config_dir], o[:artifact_file], tag: o[:tag], hash: o[:hash])
        deploy_opts = to_deploy_opts(o, :heroku_app, :heroku_stack, :procfile, :platform, :force) 
        cmd.run(deploy_opts)
      }
    end

    desc "artifact-list", "list available artifacts"
    add_opts(options, org_repo(true))
    def artifact_list
      prep(__method__, options){|o|
        cmd = List.new(o[:config_dir], get_store(o[:config_dir]))
        list = cmd.run(org: o[:org], repo: o[:repo])
        puts list
      }
    end

    desc "slug-mk-from-artifact-file", "create a heroku slug from an artifact"
    add_opts(options, platform)
    option :artifact_file, str(r:true, d: "The path to the artifact")
    option :out_path, str(r:true, d: "Where to save the slug")
    option :force, force 
    def slug_mk_from_artifact_file
      prep(__method__, options){|o| 
        cmd = MakeSlugFromArtifact.new(o[:config_dir])
        # TODO: Normalize opt names
        o[:artifact] = o[:artifact_file]
        o[:out] = o[:out_path]
        out = cmd.run(o)
      }
    end

    desc "slug-deploy-from-file", "create a heroku slug from an artifact"
    add_opts(options, heroku)
    option :slug_file, str(r:true, d: "The path to the slug")
    option :tag, str(d: "The version of the slug (typically a git tag or commit hash)")
    option :description, str(d: "A description", f: "deploy")
    option :force, force 
    def slug_deploy_from_file
      prep(__method__, options){|o|  
        cmd = DeploySlugFile.new(o[:config_dir], o[:stack])
        o[:slug] = o[:slug_file]
        cmd_opts = {
          :slug => o[:slug_file],
          :app => o[:heroku_app],
          :version => o[:tag],
          :description => o[:description]
        }
        out = cmd.run(cmd_opts)
        puts "deployed to: #{options[:app]}"
      }
    end

  end
end
