module CsBuilder
  module Git
    module GitHelper
      def commit_hash(path)
        sha = `git --git-dir=#{path}/.git --work-tree=#{path} rev-parse --short HEAD`.strip
        raise "no sha" if sha.nil? or sha.empty?
        sha
      end
    end
  end
end
