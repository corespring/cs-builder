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
      def run_build(config, force: false)
        @config = config

        run_with_lock(@config.paths.lock_file("build")) {

          @log.debug "install external src"
          install_external_src_to_repo
          @log.debug "update repo"
          update_repo
          @log.debug "get uid"
          uid = build_uid

          @log.debug("build uid set to: #{uid}")

          if(artifacts_exist?(uid) and !force )
            @log.debug "artifacts exist for #{uid}"
          else
            @log.debug "build repo for #{uid}"
            build_repo
            @log.debug "prepare binaries for #{uid}"
            # prepare_binaries(uid)
            # safely_remove_all_except(binaries_path(uid))
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

      # def prepare_binaries(uid)
      #   binary_folder = @config.binary_folder(uid)
      #   archive = @config.binary_archive(uid)
      #   @log.debug("[prepare_binaries] repo: #{@config.paths.repo} -> #{archive}")
      #   @log.debug("binary_folder: #{binary_folder}")
      #   FileUtils.mkdir_p binary_folder

      #   @config.build_assets.each{ |asset|
      #     from = "#{@config.paths.repo}/#{asset}"
      #     to = "#{binary_folder}/#{asset}"
      #     FileUtils.mkdir_p( File.dirname(to), :verbose => true)
      #     FileUtils.cp_r(from, to, :verbose => true)
      #   }

      #   system("tar", "czvf", archive, "-C", binary_folder, ".",
      #          [:out, :err] => "/dev/null")

      #   FileUtils.rm_rf(binary_folder, :verbose => true)
      #   archive
      # end

      def binaries_path(uid)
        archive = @config.binary_archive(uid)
        @log.debug "binaries -> #{archive}"
        raise "Binary doesn't exist: #{archive}" unless File.exists? archive
        archive
      end

    end

    class MakeArtifactGit < MakeArtifactBase

      include CsBuilder::Git

      def initialize(level, config_dir)
        super('make-artifact-git', level, config_dir)
      end

      def run(options)
        run_build(config_from_opts(options), force: options[:force] || false)
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

      def git(path, cmd) 
        run_shell_cmd("git --git-dir=#{path}/.git --work-tree=#{path} #{cmd}")
      end

      def install_external_src_to_repo
        path = @config.paths.repo
        branch = @config.branch
        git = @config.git
        @log.info "path: #{path}, branch: #{branch}, git: #{git}"
        FileUtils.mkdir_p(path, :verbose => true ) unless File.exists?(path)
        @log.debug "clone #{git}"
        run_shell_cmd("git clone #{git} #{path}") unless File.exists?(File.join(path, ".git"))
        @log.debug "checkout #{branch}"
        
        git(path, "checkout #{branch}")
        git(path, "branch --set-upstream-to=origin/#{branch} #{branch}")

        if File.exists?(File.join(path, ".gitmodules"))
          in_dir(path) {
            @log.debug "Init the submodules in #{path}"
            run_shell_cmd("git submodule init")
          }
        end
      end

      def update_repo
        branch = @config.branch
        path = File.expand_path(@config.paths.repo)

        @log.info "[update_repo] path: #{path}, branch: #{branch}"
        @log.debug "reset hard to #{branch}"
        
        git(path, "clean -fd")
        git(path, "reset --hard HEAD")
        git(path, "checkout #{branch}")
        git(path, "fetch origin #{branch}")
        git(path, "reset --hard origin/#{branch}")

        if File.exists? "#{path}/.gitmodules"
          in_dir(path){
            @log.debug "update all the submodules in #{path}"
            run_shell_cmd("git submodule foreach git clean -fd")
            run_shell_cmd("git pull --recurse-submodules")
            run_shell_cmd("git submodule update --recursive")
          }
        end
      end

    end
  end
end
