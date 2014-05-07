require_relative './core-command'
require_relative '../git-parser' 

module CsBuilder
  module Commands

    class BaseBuild < CoreCommand

    end

    class BuildFromGit < BaseBuild

      def initialize(level, config_dir)
        super('build-from-git', level, config_dir)
      end

      def run(options)
        git = options[:git]
        branch = options[:branch]
        cmd = options[:cmd]
        binaries = options[:binaries]
        org = GitParser.org(git)
        repo = GitParser.repo(git)
        path = repo_path(org, repo, branch)
        binary_path = binaries_path(org, repo, branch)
        @log.debug("path: #{path}")
        @log.debug("git: #{git}, branch: #{branch}, cmd: #{cmd}")
        install_repo(git, branch, path) unless File.exists?(path)
        update_repo(branch, path)
        sha = get_sha(org, repo, branch)

        if File.exists?( binary_archive_path(binary_path, sha, suffix: ".tgz"))
          @log.info("This sha has already been built #{binary_archive_path(binary_path, sha, suffix: ".tgz")}")
          0
        else
          @log.debug("sha: #{sha}, binaries path: #{binary_path}")
          build_app(path, cmd)
          prepare_binaries(path, binary_path, sha, binaries)
        end
      end

      private

      def install_repo(git, branch, path)
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

      def update_repo(branch, path)
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

      def build_app(path, cmds)
        in_dir(path){
          @log.debug( "run: #{cmds}")
          run_cmd cmds
        }
      end

      def prepare_binaries(src_path, out_path, sha, binaries)
        @log.debug("[prepare_binaries] src: #{src_path}, #{out_path}, #{binaries}")
        target = binary_archive_path(out_path, sha)
        @log.debug("target: #{target}")
        FileUtils.mkdir_p target

        binaries.each{ |b|
          from = "#{src_path}/#{b}"
          to = "#{target}/#{b}"
          FileUtils.cp_r(from, to, :verbose => true)
        }

        system("tar", "czvf", "#{target}.tgz", "-C", target, ".",
               [:out, :err] => "/dev/null")

        FileUtils.rm_rf(target, :verbose => true)
        "#{target}.tgz"
      end

    end

  end
end
