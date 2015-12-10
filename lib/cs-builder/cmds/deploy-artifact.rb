require_relative './core-command'
require_relative '../git/git-parser'
require_relative '../models/config'
require_relative '../runner'
require_relative '../io/safe-file-removal'


module CsBuilder
  module Commands

    include Models

    class DeployArtifact < CoreCommand

      include CsBuilder::Runner
      include CsBuilder::IO::SafeFileRemoval

      def initialize(log_name, config_dir)
        super(log_name, config_dir)
      end

      def runner_log(msg)
        @log.debug(msg)
      end

      protected
      def run_build(config, artifact, force: false)
        @config = config

        run_with_lock(@config.paths.lock_file("deploy-artifact")) {

          @log.debug "install external src"
          install_external_src_to_repo
          @log.debug "update repo"
          update_repo
          @log.debug "get uid"
          uid = build_uid

          @log.debug("build uid set to: #{uid}")
          @log.info("... todo ... ")
        }
      end

      def build_uid
        raise "not defined"
      end

    end

    class DeployArtifactGit < DeployArtifact

      include CsBuilder::Git
      
      def initialize(config_dir)
        super('deploy-artifact', config_dir)
      end
      
      def run(options)
        cfg = config_from_opts(options)
        @log.debug("[run] cfg: #{cfg}")
        artifact_config = {
          :format => options[:artifact_format],
          :path => options[:artifact]
        }
        run_build(cfg, artifact_config, force: options[:force] || false)
      end
      
      def install_external_src_to_repo
        GitHelper.install_external_src_to_repo(@config.paths.repo, @config.git, @config.branch, @log)
      end

      def update_repo
        GitHelper.update_repo(@config.paths.repo, @config.branch, @log)
      end

      def config_from_opts(options)
        GitConfigBuilder.from_opts(@config_dir, options)
      end

      def build_uid
        @config.uid
      end

    end
  end
end
