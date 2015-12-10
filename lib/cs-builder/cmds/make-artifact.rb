require_relative './core-command'
require_relative '../git/git-parser'
require_relative '../models/config'
require_relative '../runner'
require_relative '../io/safe-file-removal'
require_relative '../init'


module CsBuilder
  module Commands

    include Models

    class MakeArtifactGit

      include CsBuilder::Runner
      include CsBuilder::IO::SafeFileRemoval
      include CsBuilder::Git

      def initialize(config_dir)
        CsBuilder::Init.init_cs_builder_dir(config_dir)
        @config_dir = config_dir
      end
      
      def run(options)
        @repo = Repo.new(@config_dir, options[:git], options[:branch])
        @artifacts = RepoArtifacts.new(@config_dir, @repo, options[:cmd], options[:artifact])

        @log.debug("[run] cfg: #{cfg}")

        run_with_lock(@repo.lock_file) {
          @log.debug "clone repo"
          @repo.clone
          @log.debug "update repo"
          @repo.update
          hash_and_tag = @repo.hash_and_tag 

          if(force)
            @artifacts.rm_artifact(hash_and_tag) 
          end

          if(@artifacts.has_artifacts?(hash_and_tag) and !force)
            @log. info "artifacts exist for #{uid}"
            {:path => @artifacts.artifacts(uid)[0], :skipped => true}
           else
              @log.debug "build repo for #{uid}"
              result = @artifacts.build
              stored_path = @artifacts.move_to_store(
                result[:artifact],
                result[:version],
                result[:extname],
                hash_and_tag)
             
             result.merge({
              :hash => hash_and_tag.hash,
              :tag => hash_and_tag.tag,
              :path => stored_path, 
              :forced => force })
           end
        }
      end

      # def build_repo
      #   if @config.build_cmd.empty? or @config.build_cmd.nil?
      #     @log.debug "no build command to run - skipping"
      #   else
      #     in_dir(@config.paths.repo){
      #       @log.debug( "run: #{@config.build_cmd}")
      #       run_cmd @config.build_cmd
      #     }
      #   end
      # end

    end

  end
end
