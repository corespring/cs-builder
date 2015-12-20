require_relative '../log/logger'
require_relative '../in-out/utils'
require_relative '../shell/runner'
require_relative '../models/paths'
require_relative './artifact-paths'

include CsBuilder::Artifacts::ArtifactPaths

module CsBuilder
  module Artifacts

    class RepoArtifacts

      include InOut::Utils
      include ShellRunner

      def initialize(root, repo, store)
        @log = Log.get_logger('repo-artifacts')
        @repo = repo
        @store = store
      end

      def build_and_move_to_store(cmd, pattern, force:false)
        result = build(cmd, pattern, force:force)
        if(result.has_key?(:build_info))
          stored_path = move_to_store(result[:build_info])
          result.merge({:moved_to_store => true, :stored_path => stored_path})
        else
          result.merge({:moved_to_store => false})
        end
      end

      def build(cmd, pattern, force: false)

        ht = @repo.hash_and_tag

        if(force)
          rm_artifact(ht)
        end

        if(has_artifact?(ht) and !force)
          @log.warn("artifact for #{ht} already exists: #{artifact(ht)} - skipping")
          {
            :build_info => artifact(ht),
            :skipped => true,
            :forced => force
          }
        else
          in_dir(@repo.path){
            @log.debug( "run: #{cmd}")

            Dir[artifact_glob(pattern)].each{|a|
              FileUtils.rm_rf(a, :verbose => @log.debug?)
            }

            shell_run(cmd)
          }

          @log.debug "find the built artifact for hash_and_tag : #{ht}, using: #{pattern}"
          path = find_built_artifact_path(pattern)
          version = version_from_built_artifact(path, pattern)
          extname = File.extname(path)
          {
            :build_info => {
              :path => path,
              :version => version,
              :extname => extname,
              :hash_and_tag => ht
            },
            :skipped => false,
            :forced => force
          }
        end
      end

      def move_to_store(path:, version:, extname:, hash_and_tag:)
        @store.move_to_store(path, @repo.org, @repo.repo, version, hash_and_tag, extname)
      end

      def has_artifact?(hash_and_tag)
        @store.has_artifact?(@repo.org, @repo.repo, hash_and_tag)
      end

      def artifact(hash_and_tag)
        @store.artifact(@repo.org, @repo.repo, hash_and_tag)
      end

      def artifact_from_tag(tag)
        @store.artifact_from_tag(@repo.org, @repo.repo, tag)
      end

      def artifact_from_hash(hash)
        @store.artifact_from_hash(@repo.org, @repo.repo, hash)
      end

      def rm_artifact(hash_and_tag)
        @store.rm_artifact(@repo.org, @repo.repo, hash_and_tag)
      end

      private
      def artifact_glob(pattern)
        "#{@repo.path}/#{pattern.gsub(/\(.*\)/, "*")}"
      end

      def find_built_artifact_path(pattern)
        glob = artifact_glob(pattern)
        @log.debug "glob: #{glob}"
        paths = Dir[glob]
        raise "[repo-artifacts] Can't find artifact at: #{glob}" if paths.length == 0
        paths[0]
      end

      def version_from_built_artifact(artifact, pattern)
        artifact.match(/.*#{pattern}/)[1]
      end

    end
  end
end
