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
        @build_assets = build_assets
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

    class GitConfig < Config

      attr_accessor :git
      def initialize(root, external_src, org, repo, branch, build_cmd, build_assets)
        super(root, external_src, org, repo, branch, build_cmd, build_assets)
        @git = external_src
      end

      def uid
        get_sha
      end

      private

      def get_sha
        sha = `git --git-dir=#{@paths.repo}/.git --work-tree=#{@paths.repo} rev-parse --short HEAD`.strip
        raise "no sha" if sha.nil? or sha.empty?
        sha
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
