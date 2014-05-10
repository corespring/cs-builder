require 'log4r'

module CsBuilder

  module Models

    class Paths
      def initialize(root, org, repo, branch)
        @root = root
        @org = org
        @repo = repo
        @branch = branch
      end

      def repo
        make("repos")
      end

      def binaries
        make("binaries")
      end

      def slugs
        make("slugs")
      end

      def lock_file(name)
        File.join(make("locks"), "#{name}.lock")
      end

      private

      def make(key)
        File.join(@root, key, @org, @repo, @branch)
      end

    end


    class Config

      attr_accessor :paths, :cmd, :build_assets, :external_src, :build_cmd, :branch
      def initialize(root, external_src, org, repo, branch, build_cmd, build_assets)
        @paths = Paths.new(root, org, repo, branch)
        @build_cmd = build_cmd
        @build_assets = build_assets << "Procfile"
        @external_src = external_src
        @branch = branch
      end

      def uid
        raise "not defined"
      end

      def binary_archive(uid)
        File.join(@paths.binaries, "#{uid}.tgz")
      end

      def binary_folder(uid)
        File.join(@paths.binaries, uid)
      end


    end

    module GitHelper
      def commit_hash(path)
        sha = `git --git-dir=#{path}/.git --work-tree=#{path} rev-parse --short HEAD`.strip
        raise "no sha" if sha.nil? or sha.empty?
        sha
      end
    end

    module SlugHelper

      require 'yaml'

      # Get a hash from the Procfile yml file
      #
      def self.processes_from_slug(slug)
        `tar -zxvf #{slug} ./app/Procfile`
        proc_yml = YAML.load_file('./app/Procfile')
        FileUtils.rm_rf './app/Procfile'
        proc_yml
      end
    end


    class GitConfig < Config

      include GitHelper

      attr_accessor :git
      def initialize(root, external_src, org, repo, branch, build_cmd, build_assets)
        super(root, external_src, org, repo, branch, build_cmd, build_assets)
        @git = external_src
        @log = Log4r::Logger.new('git_config')
      end

      def uid
        get_sha
      end

      private

      def get_sha
        @log.debug "get sha for #{@paths.repo}"
        commit_hash(@paths.repo)
      end
    end

    class FileConfig < Config
      def initialize(root, external_src, org, repo, branch, build_cmd, build_assets, uid: Time.now.strftime('%Y%m%d%H%M%S'))
        super(root, external_src, org, repo, branch, build_cmd, build_assets)
        @uid = uid
      end

      def uid
        @uid
      end
    end

  end
end
