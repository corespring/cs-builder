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
      include CsBuilder::Io::SafeFileRemoval

      def initialize(log_name, log_level, config_dir)
        super(log_name, log_level, config_dir)
      end

      def runner_log(msg)
        @log.debug(msg)
      end

      protected
      def run_build(config, artifact, force: false)
        @config = config

        run_with_lock(@config.paths.lock_file("build")) {

          @log.debug "install external src"
          install_external_src_to_repo(@config.paths.repo, @config.git, @config.branch, @log)
          @log.debug "update repo"
          update_repo(@config.paths.repo, @config.branch, @log)
          @log.debug "get uid"
          uid = build_uid
          format = artifact[:format]

          @log.debug("build uid set to: #{uid}, format: #{format}")

          @config.artifacts(uid).each{ |p|
            @log.info("force:true -> rm: #{p}")
            FileUtils.rm_rf(p, :verbose => true) if force
          }

          if(@config.artifacts(uid).length > 0 and !force)
            @log. info "artifacts exist for #{uid}"
            {:path => @config.artifacts(uid)[0], :skipped => true}
          else
            @log.debug "build repo for #{uid}"
            build_repo
            @log.debug "find the artifact for uid: #{uid}, format: #{format}"
            search_path = "#{@config.paths.repo}/#{artifact[:path].gsub(/\(.*\)/, "*")}"
            @log.debug "search path: #{search_path}"
            paths = Dir[search_path] 
            raise "Can't find artifact at: #{search_path}" if paths.length == 0
            path = paths[0] 
            artifact_version = path.match(/.*#{artifact[:path]}/)[1]
            @log.debug "artifact-version: #{artifact_version}" 
            @log.debug "paths: #{paths}"
            suffix = File.extname(path)
            artifact_path =  File.join(@config.paths.artifacts, artifact_version, "#{uid}#{suffix}")
            FileUtils.mkdir_p(File.dirname(artifact_path), :verbose => true) 
            FileUtils.mv(path, artifact_path) 
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
      include CsBuilder::Git::GitHelper

      def initialize(level, config_dir)
        super('make-artifact-git', level, config_dir)
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

      def config_from_opts(options)

        git = options[:git]

        @log.debug(">>> options: #{options}")
        @log.debug("options[:org].nil? #{options[:org].nil?}") 
        
        org = options.has_key?(:org) ? options[:org] : GitUrlParser.org(git)
        repo = options.has_key?(:repo) ? options[:repo] : GitUrlParser.repo(git)

        @log.debug "org: #{org}, repo: #{repo}, branch: #{options[:branch]}"
        
        Models::GitConfig.new(
          @config_dir,
          options[:git],
          org,
          repo,
          options[:branch],
          options[:cmd],
          options[:build_assets]
        )
      end

      def build_uid
        @config.uid
      end

    end
  end
end
