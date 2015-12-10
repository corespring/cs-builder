require_relative './git-parser'

module CsBuilder
  module Git

    class HashAndTag
      attr_accessor :hash, :tag 
      def initialize(hash, tag = nil)
        @hash = hash
        @tag = tag
      end

      def to_simple
        if(tag.nil? or tag.empty?)
          @hash
        else 
          "#{@tag}-#{@hash}"
        end
      end
      
      def ==(other)
         self.to_simple == other.to_simple
      end

      def self.from_simple(s)
        if(s.include?("-"))
          m = s.match(/(.*)-(.*)/)
          HashAndTag.new(m[2], m[1])
        else 
          HashAndTag.new(s)
        end 
      end

    end

    class Repo

      def self.from_url(root, url, branch)
        org, repo = GitUrlParser.org_and_repo(url)
        Repo.new(root, url, org, repo, branch)
      end
      
      attr_accessor :org, :repo, :branch 
      def initialize(root, url, org, repo, branch)
        @paths = Paths.new(root, org, repo, branch)
        @url = url
        @branch = branch
        @org = org
        @repo = repo
        @branch = branch
      end

      def path
        @paths.repo
      end

      def lock_file
        @paths.lock_file("repo")
      end

      def clone
        GitHelper.clone_repo(@paths.repo, @url, @branch)
      end

      def update
        GitHelper.update_repo(@paths.repo, @url, @branch)
      end

      def hash_and_tag
        hash = GitHelper.commit_hash(@paths.repo)
        tag = GitHelper.commit_tag(@paths.repo)
        HashAndTag.new(hash, tag: tag)
      end
    
    end
  end
end