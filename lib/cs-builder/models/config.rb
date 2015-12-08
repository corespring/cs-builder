require_relative "../git/git-helper"
require_relative "./paths"


module CsBuilder

  module Models

    class Config

      attr_accessor :paths, :cmd, :external_src, :build_cmd, :branch
      def initialize(root, external_src, org, repo, branch, build_cmd, build_assets)
        @paths = Paths.new(root, org, repo, branch)
        @build_cmd = build_cmd
        @internal_build_assets = build_assets
        @external_src = external_src
        @branch = branch
      end

      def uid
        raise "not defined"
      end


      def artifacts(uid) 
        Dir["#{@paths.artifacts}/**/#{uid}*"] 
      end

      def binary_archive(uid)
        File.join(@paths.binaries, "#{uid}.tgz")
      end

      def binary_folder(uid)
        File.join(@paths.binaries, uid)
      end

      def has_assets_to_build?
        build_assets.length > 0
      end

      def build_assets
        if @internal_build_assets.nil? || @internal_build_assets.length == 0
          []
        else
          out = @internal_build_assets << "Procfile"
          out.uniq
        end
      end

    end

    class GitConfig < Config

      include Git::GitHelper

      attr_accessor :git
      def initialize(root, external_src, org, repo, branch, build_cmd, build_assets)
        super(root, external_src, org, repo, branch, build_cmd, build_assets)
        @git = external_src
        @log = Log4r::Logger.new('git_config')
      end

      def uid
        git_uid(@paths.repo)
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
