require_relative './core-command'
require_relative '../git-parser'
require_relative '../models'
require_relative '../runner'

module CsBuilder
  module Commands

    include Models

    class BaseBuild < CoreCommand

      include CsBuilder::Runner

      def initialize(log_name, log_level, config_dir)
        super(log_name, log_level, config_dir)
      end

      def runner_log(msg)
        @log.debug(msg)
      end

      protected
      def run_build(config, force: false)
        @config = config

        run_with_lock(@config.paths.lock_file("build")) {

          @log.debug "install external src"
          install_external_src_to_repo
          @log.debug "update repo"
          update_repo
          @log.debug "get uid"
          uid = build_uid

          if(binaries_exist?(uid) and !force )
            @log.debug "binaries exist for #{uid}"
          else
            @log.debug "build repo for #{uid}"
            build_repo
            @log.debug "prepare binaries for #{uid}"
            prepare_binaries(uid)
          end
          @log.debug "get binaries path for #{uid}"
          binaries_path(uid)
        }
      end

      def install_external_src_to_repo
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
        binary_folder = @config.binary_folder(uid)
        archive = @config.binary_archive(uid)
        @log.debug("[prepare_binaries] repo: #{@config.paths.repo} -> #{archive}")
        @log.debug("binary_folder: #{binary_folder}")
        FileUtils.mkdir_p binary_folder

        @config.build_assets.each{ |asset|
          from = "#{@config.paths.repo}/#{asset}"
          to = "#{binary_folder}/#{asset}"
          FileUtils.cp_r(from, to, :verbose => true)
        }

        system("tar", "czvf", archive, "-C", binary_folder, ".",
               [:out, :err] => "/dev/null")

        FileUtils.rm_rf(binary_folder, :verbose => true)
        archive
      end

      def binaries_path(uid)
        archive = @config.binary_archive(uid)
        @log.debug "binaries -> #{archive}"
        raise "Binary doesn't exist: #{archive}" unless File.exists? archive
        archive
      end

    end

    class BuildFromFile < BaseBuild
      def initialize(level, config_dir)
        super('build-from-file', level, config_dir)
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

      def install_external_src_to_repo
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

      def initialize(level, config_dir)
        super('build-from-git', level, config_dir)
      end

      def run(options)
        run_build(config_from_opts(options), force: options[:force] || false)
      end

      def config_from_opts(options)

        org = GitParser.org(options[:git])
        repo = GitParser.repo(options[:git])

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

      def install_external_src_to_repo
        path = @config.paths.repo
        branch = @config.branch
        git = @config.git
        @log.info "path: #{path}, branch: #{branch}, git: #{git}"
        FileUtils.mkdir_p(path, :verbose => true )
        @log.debug "clone #{git}"
        `git clone #{git} #{path}`
        @log.debug "checkout #{branch}"
        `git --git-dir=#{path}/.git --work-tree=#{path} checkout #{branch}`

        if File.exists? "#{path}/.gitmodules"
          in_dir(path) {
            @log.debug "Init the submodules in #{path}"
            `git submodule init`
          }
        end
      end

      def update_repo
        branch = @config.branch
        path = @config.paths.repo

        @log.info "[update_repo] path: #{path}, branch: #{branch}"
        @log.debug "reset hard to #{branch}"
        `git --git-dir=#{path}/.git --work-tree=#{path} reset --hard HEAD`
        `git --git-dir=#{path}/.git --work-tree=#{path} pull origin #{branch}`
        if File.exists? "#{path}/.gitmodules"
          in_dir(path){
            @log.debug "update all the submodules in #{path}"
            `git pull --recurse-submodules`
            `git submodule update --recursive`
          }
        end
      end

    end
  end
end
