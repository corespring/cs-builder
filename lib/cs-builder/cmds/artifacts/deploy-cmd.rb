require_relative '../../init'
require_relative '../../log/logger'
require_relative '../../heroku/slug-from-template'
require_relative '../../heroku/heroku-deployer'
require_relative '../../heroku/heroku-description'
require_relative '../../git/repo'
require_relative '../../git/git-parser'
require_relative '../../artifacts/repo-artifacts'

require 'tmpdir'

include CsBuilder::Heroku
include CsBuilder::Git
include CsBuilder::Artifacts

module CsBuilder
  module Commands
    module Artifacts

      class DeployCommand

        def initialize(config_dir)
          CsBuilder::Init.init_cs_builder_dir(config_dir)
          @config_dir = config_dir
          @_log = CsBuilder::Log.get_logger("deploy-command")
        end

        def load_artifact
          raise "abstract method: load_artifact"
        end

        def run(heroku_app:, platform:, heroku_stack: "cedar-14", procfile: "Procfile", force: false)
          @_log.info(__method__)

          app = heroku_app

          if(app.nil?)
            @_log.warn("app is nil")
            return
          end

          artifact = load_artifact

          if(artifact.nil?)
            msg = "No artifact found, have you built it yet?"
            @_log.warn("#{msg}")

            not_deployed_result({}, {
              :deployed => false,
              :message => msg
            })
          else

            @_log.debug("artifact: #{artifact}")
            out_path = File.join(Dir.mktmpdir("deploy-from-branch_") , "#{artifact[:hash_and_tag].hash}-#{platform}.tgz")
            slug = SlugFromTemplate.mk_slug(artifact[:path], out_path, platform, File.join(@config_dir, "templates"), force == true)

            ht = artifact[:hash_and_tag]
            
            description = HerokuDescription.new(
              artifact[:version],
              ht.hash,
              ht.tag).json_string

            deployer = HerokuDeployer.new

            @_log.debug("app: #{app}, stack: #{heroku_stack}, description: #{description}, slug: #{slug}, procfile: #{procfile}")

            release_response = deployer.deploy(
              slug,
              SlugHelper.processes_from_slug(slug, procfile: procfile),
              app,
              artifact[:hash],
              description,
              heroku_stack,
              force: force)

            @_log.debug("release_response: #{release_response}")
            @_log.debug("removing the slug: #{slug}")
            FileUtils.rm_rf(slug, :verbose => @_log.debug?)

            deployed_result({}, {
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

    end
  end
end
