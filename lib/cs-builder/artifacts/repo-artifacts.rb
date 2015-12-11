require_relative '../log/logger'
require_relative '../io/utils'
require_relative '../shell/runner'

module CsBuilder
  module Artifacts

    class RepoArtifacts

      include IO::Utils 
      include ShellRunner


      def initialize(root, repo, cmd, artifact_pattern)
        @log = Log.get_logger('repo-artifacts')
        @repo = repo  
        @cmd = cmd
        @artifact_pattern = artifact_pattern
        @paths = Paths.new(root, @repo.org, @repo.repo, @repo.branch)
      end


      def build_and_move_to_store(force:false)
        result = build(force:force)
        if(result.has_key?(:build_info))
          stored_path = move_to_store(result[:build_info])
          result.merge({:moved_to_store => true, :stored_path => stored_path})
        else 
          result.merge({:moved_to_store => false})
        end
      end

      def build(force: false)

        ht = @repo.hash_and_tag

        if(force)
          rm_artifact(ht)
        end

        if(has_artifact?(ht) and !force)
          @log.warn("artifact for #{ht} already exists: #{artifact(ht)} - skipping") 
          {
            :existing_artifact => artifact(ht), 
            :skipped => true, 
            :forced => force
          }
        else 
          in_dir(@repo.path){
            @log.debug( "run: #{@cmd}")
            
            Dir[artifact_glob].each{|a|
              FileUtils.rm_rf(a, :verbose => @log.debug?)
            }

            run_shell_cmd @cmd
          }

          @log.debug "find the built artifact for hash_and_tag : #{ht}, using: #{@artifact_pattern}"
          new_artifact = find_built_artifact
          version = get_version_from_artifact(new_artifact) 
          extname = File.extname(new_artifact)
          {
            :build_info => {
              :artifact => new_artifact, 
              :version => version, 
              :extname => extname,
              :hash_and_tag => ht
            },
            :skipped => false, 
            :forced => force
          }
        end
      end

      def move_to_store(artifact:, version:, extname:, hash_and_tag:)
        base_path = @paths.artifacts
        store_path =  File.join(base_path, version, "#{hash_and_tag.to_simple}#{extname}")
        @log.debug("store_path: #{store_path}")
        FileUtils.mkdir_p(File.dirname(store_path), :verbose => @log.debug?) 
        FileUtils.mv(artifact, store_path) 
        store_path
      end

      def has_artifact?(hash_and_tag)
        !artifact(hash_and_tag).nil? 
      end
      
      # get artifacts by the git sha + maybe tag
      def artifact(hash_and_tag)
        artifact_from_key(hash_and_tag.to_simple)
      end
      
      def artifact_from_tag(tag)
        artifact_from_key(tag)
      end
      
      def artifact_from_hash(hash)
        artifact_from_key(hash)
      end

      def rm_artifact(hash_and_tag) 
        artifacts_from_key(hash_and_tag.to_simple).each{|p|
          @log.info("force:true -> rm: #{p}") 
          FileUtils.rm_rf(p, :verbose => @log.debug?) 
        }
      end

      private 

      def artifact_glob
        "#{@repo.path}/#{@artifact_pattern.gsub(/\(.*\)/, "*")}"
      end

      def find_built_artifact
        @log.debug "glob: #{artifact_glob}"
        paths = Dir[artifact_glob] 
        raise "[repo-artifacts] Can't find artifact at: #{artifact_glob}" if paths.length == 0
        paths[0] 
      end

      def artifact_from_key(key)
        found = artifacts_from_key(key)
        if(found.length > 0)
          found[0]
        else 
          nil
        end
      end
      
      def artifacts_from_key(key)
        Dir["#{@paths.artifacts}/**/*#{key}*.tgz"]
      end

      def get_version_from_artifact(artifact)
        artifact.match(/.*#{@artifact_pattern}/)[1]
      end

    end
  end
end