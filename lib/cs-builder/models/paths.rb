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
  end
end
