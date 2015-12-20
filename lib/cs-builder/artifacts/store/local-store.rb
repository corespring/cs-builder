require_relative '../../log/logger'
require_relative './base-store'

module CsBuilder
  module Artifacts
    ##
    # A store that uses the local filesystem.
    class LocalStore < BaseStore

      ##
      # :arg: artifacts_root - the directory in which to store and look for artifacts
      #
      def initialize(artifacts_root)
        super()
        @log = Log.get_logger("local-store")
        @artifacts_root = artifacts_root
        @log.info("@artifacs_root: #{@artifacts_root}")
      end

      ##
      # Move the file to a location
      def mv_path(from, to, force:false)
        final_to = resolve_path(to)
        @log.debug("[mv_path] #{from} -> #{final_to}, force: #{force}")
        FileUtils.mkdir_p(File.dirname(final_to), :verbose => @log.debug?)
        FileUtils.mv(from, final_to, :force => force, :verbose => @log.debug?)
        to
      end

      # remove the file referenced by the path
      def rm_path(path)
        FileUtils.rm_rf(resolve_path(path), :verbose => @log.debug?)
      end

      ##
      # does the file exist?
      #
      # Eg:
      #
      #    path_exists?("org/repo/0.1/hash-tag.tgz")
      #
      # will check: +/user/ed/home/path/to/artifacts/org/repo/0.1/hash-tag.tgz+
      #
      def path_exists?(path)
        out = File.exist?(resolve_path(path))
        @log.debug("path_exists?('#{path}'): #{out}")
        out
      end

      def artifacts_from_key(org, repo, key)
        @log.debug("[artifacts_from_key] org: #{org}, repo: #{repo}, key: #{key}")
        glob = "#{@artifacts_root}/#{org}/#{repo}/**/*#{key}*.tgz"
        @log.debug("glob: #{glob}")

        out = Dir[glob].map{|full_path|
          strip_path(full_path)
        }

        @log.debug("[artifacts_from_key] out: #{out}")
        out
      end

      def resolve_path(path)
        File.join(@artifacts_root, path)
      end

      private
      def strip_path(path)
        path.sub(/^#{@artifacts_root}\//, "")
      end
    end
  end
end
