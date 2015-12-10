require_relative './core-command'
require_relative '../git/git-parser'
require_relative '../models/config'
require_relative '../runner'
require_relative '../io/safe-file-removal'
require_relative '../io/archive'


module CsBuilder
  module Commands

    include Models

    class BaseBuild < CoreCommand

      include CsBuilder::Runner
      include CsBuilder::IO::SafeFileRemoval
      include CsBuilder::IO

      def initialize(log_name, config_dir)
        super(log_name, config_dir)
      end

      def runner_log(msg)
        @log.debug(msg)
      end

      protected
      def run_build(config, force: false)
        @config = config

        run_with_lock(@config.paths.lock_file("build")) {

          @log.debug "install external src"
          clone_repo
          @log.debug "update repo"
          update_repo
          @log.debug "get uid"
          uid = build_uid

          @log.debug("build uid set to: #{uid}")

          if(!@config.has_assets_to_build?)
            @log.info("no assets to build - just run the build command: #{@config.build_cmd}")
            build_repo
            ""
          else
            if(binaries_exist?(uid) and !force )
              @log.debug "binaries exist for #{uid}"
            else
              @log.debug "build repo for #{uid}"
              build_repo
              @log.debug "prepare binaries for #{uid}"
              prepare_binaries(uid)
              safely_remove_all_except(binaries_path(uid))
            end
            @log.debug "get binaries path for #{uid}"
            binaries_path(uid)
          end
        }
      end

      def clone_repo
        raise "not defined"
      end

      def update_repo
        raise "not defined"
      end

      def build_uid
        raise "not defined"
      end

      def binaries_exist?(uid)
        File.exists? @config.binary_archive(uid)
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

      def prepare_binaries(uid)
        archive = @config.binary_archive(uid)
        archive_path = IO::Archive.create(@config.paths.repo, archive, @config.build_assets)
        raise "Archive #{archive_path} doesn't exist" unless File.exists?(archive_path)
        @log.debug("created archive here: #{archive_path}, archive in: #{archive}")
      end

      def binaries_path(uid)
        archive = @config.binary_archive(uid)
        @log.debug "binaries -> #{archive}"
        raise "Binary doesn't exist: #{archive}" unless File.exists? archive
        archive
      end

    end

    class BuildFromFile < BaseBuild

      include CsBuilder::Models

      def initialize(config_dir)
        super('build-from-file', config_dir)
      end

      def run(options)
        run_build(config_from_opts(options), force: options[:force] || false)
      end

      def config_from_opts(options)
        FileConfig.new(
          @config_dir,
          options[:external_src],
          options[:org],
          options[:repo],
          options[:branch],
          options[:cmd],
          options[:build_assets],
          uid: options[:uid] || Time.now.strftime('%Y%m%d%H%M%S')
        )
      end

      def clone_repo
        FileUtils.mkdir_p(File.dirname(@config.paths.repo), :verbose => true )
        FileUtils.cp_r(@config.external_src, @config.paths.repo, :verbose => true)
      end

      def update_repo
        @log.debug "[update_src] - nothing to do when building from file"
      end

      def build_uid
        @config.uid
      end

    end

    class BuildFromGit < BaseBuild

      include CsBuilder::Git

      def initialize(config_dir)
        super('build-from-git', config_dir)
      end

      def run(options)
        run_build(config_from_opts(options), force: options[:force] || false)
      end

      def config_from_opts(options)
        GitConfigBuilder.from_opts(@config_dir, options)
      end

      def build_uid
        @config.uid
      end

      def clone_repo
        GitHelper.clone_repo(@config.paths.repo, @config.git, @config.branch, @log)
      end

      def update_repo
        GitHelper.update_repo(@config.paths.repo, @config.branch, @log)
      end

    end
  end
end
