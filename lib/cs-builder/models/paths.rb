require 'log4r'

module CsBuilder

  module Models

    class Paths
      def initialize(root, org, repo, branch)
        @log = Log4r::Logger.new('paths')
        @log.outputters << Log4r::StdoutOutputter.new('log_stdout') #, :level => Log4r::WARN )
        @log.level = 1
        @log.debug('init')
        @root = root
        @org = org
        @repo = repo
        @branch = branch
        @log.info("init @root: #{@root}, @org: #{@org}, @repo: #{@repo}, @branch: #{@branch}")
        
        raise "@root is nil" if @root.nil?
        raise "@org is nil" if @org.nil?
        raise "@repo is nil" if @repo.nil?
        raise "@branch is nil" if @branch.nil?
      end

      # Note: artifacts don't have branch directories
      def artifacts
        File.join(@root, "artifacts", @org, @repo)
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
        @log.debug("make: key: #{key}")
        File.join(@root, key, @org, @repo, @branch)
      end

    end
  end
end
