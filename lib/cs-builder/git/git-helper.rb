module CsBuilder
  module Git
    module GitHelper extend CsBuilder::ShellRunner

      def self.git_uid(repo_path)
        tag = commit_tag(repo_path) 
        hash = commit_hash(repo_path) 
        tag.nil? ? hash : tag 
      end 

      def self.commit_tag(path)
        tag = run_git(path, "tag --contains HEAD").strip.chomp
        if tag.empty?
          nil
        else 
          tag
        end
      end
      
      def self.commit_hash(path)
        sha = run_git(path, "rev-parse --short HEAD").strip
        raise "no sha" if sha.nil? or sha.empty?
        sha
      end

      def self.install_external_src_to_repo(path, git_repo, branch, log)
        log.info "path: #{path}, branch: #{branch}"
        FileUtils.mkdir_p(path, :verbose => true ) unless File.exists?(path)
        run_shell_cmd("git clone #{git_repo} #{path}") unless File.exists?(File.join(path, ".git"))
        log.debug "checkout #{branch}"
        
        run_git(path, "checkout #{branch}")
        run_git(path, "branch --set-upstream-to=origin/#{branch} #{branch}")

        if File.exists?(File.join(path, ".gitmodules"))
          in_dir(path) {
            log.debug "Init the submodules in #{path}"
            run_shell_cmd("git submodule init")
          }
        end
      end

      def self.update_repo(path, branch, log)
        log.info "[update_repo] path: #{path}, branch: #{branch}"
        log.debug "reset hard to #{branch}"
        
        run_git(path, "clean -fd")
        run_git(path, "reset --hard HEAD")
        run_git(path, "checkout #{branch}")
        run_git(path, "fetch origin #{branch}")
        run_git(path, "reset --hard origin/#{branch}")

        if File.exists? "#{path}/.gitmodules"
          in_dir(path){
            log.debug "update all the submodules in #{path}"
            run_shell_cmd("git submodule foreach git clean -fd")
            run_shell_cmd("git pull --recurse-submodules")
            run_shell_cmd("git submodule update --recursive")
          }
        end
      end

      private 

      def self.run_git(path, cmd) 
        run_shell_cmd("git --git-dir=#{path}/.git --work-tree=#{path} #{cmd}")
      end

    end
  end
end
