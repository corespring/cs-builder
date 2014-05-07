module CsBuilder

  module Models


    class Config 

      def initialize(root, org, repo, branch)
        @root = root_dir
        @org = org
        @repo = repo
        @branch = branch
      end

      def self.from_git(root,git,branch)
        org = GitParser.org(git)
        repo = GitParser.repo(git)
        Config.new(root, org, repo, branch)
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

      def get_sha
        sha = `git --git-dir=#{repo}/.git --work-tree=#{repo} rev-parse --short HEAD`.strip
        raise "no sha" if sha.nil? or sha.empty?
        sha
      end

      private 

      def make_path(key)
        File.join(@root, key, org, repo, branch)
      end

    end

  end

  class BuildConfig < Config
  end
end
