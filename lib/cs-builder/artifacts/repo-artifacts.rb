require_relative '../log/logger'

module CsBuilder
  module Artifacts

    class RepoArtifacts

      def initialize(root, repo, cmd, artifact_pattern)
        @log = Log.get_logger('repo-artifacts')
        @repo = repo  
        @cmd = cmd
        @artifact_pattern = artifact_pattern
        @paths = Paths.new(root, @repo.org, @repo.repo, @repo.branch)
      end

      def artifact_glob
        "#{@repo.path}/#{@artifact_pattern.gsub(/\(.*\)/, "*")}"
      end

      def find_artifact
        @log.debug "glob: #{artifact_glob}"
        paths = Dir[artifact_glob] 
        raise "[repo-artifacts] Can't find artifact at: #{artifact_glob}" if paths.length == 0
        paths[0] 
      end

      def get_version_from_artifact(artifact)
        artifact.match(/.*#{@artifact_pattern}/)[1]
      end

      def build
        in_dir(@repo.path){
          @log.debug( "run: #{@cmd}")
          run_cmd @cmd
        }

        @log.debug "find the built artifact for uid: #{uid}, using: #{artifact[:path]}"
        artifact = find_artifact
        version = get_version_from_artifact 
        extname = File.extname(artifact)
        {:artifact => artifact, :version => version, :extname => extname}
      end

      def move_to_store(artifact, version, extname, hash_and_tag)
        base_path = @paths.artifacts
        store_path =  File.join(base_path, version, "#{hash_and_tag.to_simple}#{extname}")
        @log.debug("store_path: #{store_path}")
        FileUtils.mkdir_p(File.dirname(store_path), :verbose => @log.debug?) 
        FileUtils.mv(artifact, store_path) 
      end

      # get artifacts by the git sha + maybe tag
      def artifact(hash_and_tag)
        if artifacts(hash_and_tag).length > 0
          out[0]
        else 
          nil
        end
      end

      def has_artifact?(hash_and_tag)
        !artifact(hash_and_tag).nil? 
      end

      def rm_artifact(hash_and_tag) 
        artifacts(hash_and_tag).each{|p|
          @log.info("force:true -> rm: #{p}") 
          FileUtils.rm_rf(p, :verbose => @log.debug?) 
        }
      end

      private 
      def artifacts(hash_and_tag)
        base_path = @paths.artifacts
        Dir["#{base_path}/**/#{hash_and_tag.to_simple}.tgz"]
      end

    end
  end
end