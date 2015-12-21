require_relative '../artifact-paths'
require_relative '../../log/logger'

module CsBuilder
  module Artifacts
    class BaseStore

      def initialize
        @log = Log.get_logger('base-store')
      end

      def move_to_store(path, org, repo, version, hash_and_tag, force: false)

        raise "path: #{path} doesn't exist - can't move it" unless File.exist?(path)
        raise "path: #{path} is a directory - can't move it" if File.directory?(path)

        store_path = ArtifactPaths.mk(org, repo, version, hash_and_tag, extname: ".tgz")

        if(force)
          rm_path(store_path)
        end

        if(path_exists?(store_path) and !force)
          {:path => resolve_path(store_path), :virtual_path => store_path, :moved => false}
        else
          @log.debug("store_path: #{store_path}")
          mv_path(path, store_path)
          {:path => resolve_path(store_path), :virtual_path => store_path, :moved => true}
        end
      end

      def has_artifact?(org, repo, hash_and_tag)
        !artifact(org, repo, hash_and_tag).nil?
      end

      # get artifacts by the git sha + maybe tag
      def artifact(org, repo, hash_and_tag)
        @log.debug("[artifact] org: #{org}, repo: #{repo}, hash_and_tag: #{hash_and_tag}")
        path = artifact_from_key(org, repo, hash_and_tag.to_simple)

        unless path.nil?
          version = read_version_from_artifact(path)
          {:path => resolve_path(path), :virtual_path => path, :hash_and_tag => hash_and_tag, :version => version}
        end
      end

      def artifact_from_hash(org, repo, hash)
        @log.debug("[#{__method__}] org: #{org}, repo: #{repo}, hash: #{hash}")
        path = artifact_from_key(org, repo,hash) 

        unless path.nil?
          ht = HashAndTag.from_simple(File.basename(path, ".tgz"))
          version = read_version_from_artifact(path)
          {:path => resolve_path(path), :virtual_path => path, :hash_and_tag => ht, :version => version}
        end
      end

      def rm_artifact(org, repo, hash_and_tag)
        artifacts_from_key(org, repo, hash_and_tag.to_simple).each{|p|
          @log.info("force:true -> rm: #{p}")
          rm_path(p)
        }
      end

      private

      def read_version_from_artifact(path)
        File.basename(File.dirname(path))
      end

      def artifact_from_key(org, repo, key)
        found = artifacts_from_key(org, repo, key)
        
        if found.length > 1
          @log.warn("found more than one artifact by key: #{key}") 
          @log.warn("artifacts: #{found}") 
        end

        if(found.length > 0)
          found[0]
        else
          nil
        end
      end
    end
  end
end
