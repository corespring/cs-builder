require_relative './git-parser'
require_relative './git-helper'
require_relative '../models/paths'
require_relative './hash-and-tag'

include CsBuilder::Models

module CsBuilder
  module Git
    class Repo

      def self.from_url(root, url, branch)
        org, repo = GitUrlParser.org_and_repo(url)
        Repo.new(root, url, org, repo, branch)
      end

      attr_accessor :org, :repo, :branch
      def initialize(root, url, org, repo, branch)
        @root = root
        @url = url
        @branch = branch
        @org = org
        @repo = repo
        @branch = branch
        @paths = Paths.new(@root, @org, @repo, @branch)
      end

      def path
        @paths.repo
      end

      def lock_file
        @paths.lock_file("repo")
      end

      def clone
        GitHelper.clone_repo(path, @url, @branch)
      end

      def update
        GitHelper.update_repo(path, @branch)
      end

      def has_tag?(tag)
        GitHelper.has_tag?(path, tag)
      end

      def hash_for_tag(tag)
        GitHelper.hash_for_tag(path, tag)
      end

      def clone_and_update
        clone
        update
      end

      def hash_and_tag
        hash = GitHelper.commit_hash(path)
        tag = GitHelper.commit_tag(path)
        HashAndTag.new(hash,tag)
      end

    end
  end
end
