require_relative '../../init'
require_relative '../../log/logger'
require_relative '../../heroku/slug-from-template'
require_relative '../../heroku/heroku-deployer'
require_relative '../../heroku/heroku-description'
require_relative '../../git/repo'
require_relative '../../artifacts/repo-artifacts'

require 'tmpdir'

module CsBuilder
  module Commands
    module Artifacts

      include Heroku
      
      include CsBuilder::Git 

      include CsBuilder::Artifacts 

      class DeployCommand

        def initialize(config_dir)
          CsBuilder::Init.init_cs_builder_dir(config_dir)
          @config_dir = config_dir
          @_log = CsBuilder::Log.get_logger("deploy-command")
        end

        
        def load_artifact
          nil
        end 

        def run(options)
          @_log.debug("options: #{options}")

          app = options[:heroku_app]

          if(app.nil?)
            @_log.warn("app is nil")
            return
          end

          artifact = load_artifact(options)

          if(artifact.nil?)
            msg = "No artifact found, have you built it yet?"
            @_log.warn("#{msg}")
            
            not_deployed_result(options, {
              :deployed => false,
              :message => msg
            })
          else 

            @_log.debug("artifact: #{artifact}")
            template = options[:platform]
            out_path = File.join(Dir.mktmpdir("deploy-from-branch_") , "#{artifact[:hash]}-#{template}.tgz")
            slug = SlugFromTemplate.mk_slug(artifact[:path], out_path, template, File.join(@config_dir, "templates"), options[:force] == true)
            app = options[:heroku_app]
            
            description = HerokuDescription.new(
              artifact[:version],
              artifact[:hash],
              artifact[:tag]).json_string
            
            stack = options[:heroku_stack]
            
            deployer = HerokuDeployer.new

            procfile = options.has_key?(:procfile) ? options[:procfile] : "Procfile"
            
            @_log.debug("app: #{app}, stack: #{stack}, description: #{description}, slug: #{slug}, procfile: #{procfile}")

            release_response = deployer.deploy(
              slug, 
              SlugHelper.processes_from_slug(slug, procfile: procfile), 
              app, 
              artifact[:hash], 
              description, 
              stack,
              force: options[:force] == true)

            @_log.debug("release_response: #{release_response}")
            @_log.debug("removing the slug: #{slug}")
            FileUtils.rm_rf(slug, :verbose => @_log.debug?)

            deployed_result(options, {
              :deployed => !release_response.nil?, 
              :description => description
            })

          end
        end

        protected 
        
        def not_deployed_result(options, base)
          base
        end 
        
        def deployed_result(options, base)
          base
        end 

      end

      class DeployFromRepoCommand < DeployCommand

        def load_artifact(options)
          git_url = options[:git]
          org = org_from_opts(options)
          repo = repo_from_opts(options)
          branch = options[:branch]
          @repo = Git::Repo.new(@config_dir, git_url, org, repo, branch)
          @repo.clone_and_update
          @artifacts = Artifacts::RepoArtifacts.new(@config_dir, @repo)
          find_artifact_from_repo_artifacts(options, @repo, @artifacts)
        end

        def not_deployed_result(options, base)
          add_git_info(options, base)
        end

        def deployed_result(options, base)
          add_git_info(options, base)
        end

        def add_git_info(options, base)
          ht = @repo.hash_and_tag
          org = org_from_opts(options)
          base.merge({
              :url => options[:git],
              :sha => ht.hash,
              :org => org,
              :branch => options[:branch]
          })

        end

        def org_from_opts(options)
          options.has_key?(:org) ? options[:org] : GitUrlParser.org(git_url)
        end
        
        def repo_from_opts(options)
          options.has_key?(:repo) ? options[:repo] : GitUrlParser.org(git_url)
        end

      end
    end
  end
end
