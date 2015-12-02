module CsBuilder
  module Git
    module GitHelper
      
      def git_uid(repo_path)
        tag = commit_tag(repo_path) 
        hash = commit_hash(repo_path) 
        tag.nil? ? hash : tag 
      end 

      def commit_tag(path)
        tag = `#{base_cmd(path)} tag --contains HEAD`.strip.chomp
        if tag.empty?
          nil
        else 
          tag
        end
      end
      
      def commit_hash(path)
        sha = `#{base_cmd(path)} rev-parse --short HEAD`.strip
        raise "no sha" if sha.nil? or sha.empty?
        sha
      end

      private 
      def base_cmd(path)
        "git --git-dir=#{path}/.git --work-tree=#{path} "
      end

    end
  end
end
