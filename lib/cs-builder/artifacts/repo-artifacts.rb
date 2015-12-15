require_relative '../log/logger'
require_relative '../in-out/utils'
require_relative '../shell/runner'
require_relative '../models/paths'

module CsBuilder
  module Artifacts

    class RepoArtifacts

      include InOut::Utils 
      include ShellRunner


      def initialize(root, repo)
        @log = Log.get_logger('repo-artifacts')
        @repo = repo  
        @paths = Paths.new(root, @repo.org, @repo.repo, @repo.branch)
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
            :existing_artifact => artifact(ht), 
            :skipped => true, 
            :forced => force
          }
        else 
          in_dir(@repo.path){
            @log.debug( "run: #{cmd}")
            
            Dir[artifact_glob(pattern)].each{|a|
              FileUtils.rm_rf(a, :verbose => @log.debug?)
            }

            shell_run cmd
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
        base_path = @paths.artifacts
        store_path =  File.join(base_path, version, "#{hash_and_tag.to_simple}#{extname}")
        @log.debug("store_path: #{store_path}")
        FileUtils.mkdir_p(File.dirname(store_path), :verbose => @log.debug?) 
        FileUtils.mv(path, store_path) 
        store_path
      end

      def has_artifact?(hash_and_tag)
        !artifact(hash_and_tag).nil? 
      end
      
      # get artifacts by the git sha + maybe tag
      def artifact(hash_and_tag)

        path = artifact_from_key(hash_and_tag.to_simple)

        unless path.nil?
          version = read_version_from_artifact(path) 
          {:path => path, :hash => hash_and_tag.hash, 
            :tag => hash_and_tag.tag, :version => version} 
        end

      end
      
      def artifact_from_tag(tag)
        path = artifact_from_key(tag)

        unless path.nil?
          ht = HashAndTag.from_simple(File.basename(path, ".tgz"))
          version = read_version_from_artifact(path)
          {:path => path, :hash => ht.hash, :tag => ht.tag, :version => version}
        end
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

      def read_version_from_artifact(path)
        File.basename(File.dirname(path))
      end

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

      def version_from_built_artifact(artifact, pattern)
        artifact.match(/.*#{pattern}/)[1]
      end

    end
  end
end