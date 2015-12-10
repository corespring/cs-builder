require_relative './core-command'
require_relative '../git/git-parser'
require_relative '../models/config'
require_relative '../runner'
require_relative '../io/safe-file-removal'


module CsBuilder
  module Commands

    include Models

    class MakeArtifactBase < CoreCommand

      include CsBuilder::Runner
      include CsBuilder::IO::SafeFileRemoval

      def initialize(log_name, config_dir)
        super(log_name, config_dir)
      end

      def runner_log(msg)
        @log.info(msg)
      end

      protected
      def run_build(config, artifact, force: false)
        @config = config

        run_with_lock(@config.paths.lock_file("build")) {

          @log.debug "install external src"
          install_external_src_to_repo
          @log.debug "update repo"
          update_repo
          @log.debug "get uid"
          uid = build_uid

          @log.debug("build uid set to: #{uid}")

          @config.artifacts(uid).each{ |p|
            @log.info("force:true -> rm: #{p}") if force
            FileUtils.rm_rf(p, :verbose => false) if force
          }

          if(@config.artifacts(uid).length > 0 and !force)
            @log. info "artifacts exist for #{uid}"
            {:path => @config.artifacts(uid)[0], :skipped => true}
          else
            @log.debug "build repo for #{uid}"
            build_repo
            @log.debug "find the built artifact for uid: #{uid}, using: #{artifact[:path]}"
            search_path = "#{@config.paths.repo}/#{artifact[:path].gsub(/\(.*\)/, "*")}"
            @log.debug "search path: #{search_path}"
            paths = Dir[search_path] 
            raise "[make-artifact] Can't find artifact at: #{search_path}" if paths.length == 0
            built_path = paths[0] 
            artifact_version = built_path.match(/.*#{artifact[:path]}/)[1]
            @log.debug "artifact-version: #{artifact_version}" 
            @log.debug "paths: #{paths}"
            suffix = File.extname(built_path)
            artifact_path =  File.join(@config.paths.artifacts, artifact_version, "#{uid}#{suffix}")
            FileUtils.mkdir_p(File.dirname(artifact_path), :verbose => false) 
            FileUtils.mv(built_path, artifact_path) 
            @log.debug "get binaries path for #{uid}"
            {:path => artifact_path, :forced => force }
          end
        }
      end

      def build_uid
        raise "not defined"
      end

      def build_repo
        if @config.build_cmd.empty? or @config.build_cmd.nil?
          @log.debug "no build command to run - skipping"
        else
          in_dir(@config.paths.repo){
            @log.debug( "run: #{@config.build_cmd}")
            run_cmd @config.build_cmd
          }
        end
      end

    end

    class MakeArtifactGit < MakeArtifactBase

      include CsBuilder::Git
      
      def initialize(config_dir)
        super('make-artifact-git', config_dir)
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
