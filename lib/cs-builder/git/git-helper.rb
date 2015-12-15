require_relative '../log/logger'
require_relative '../shell/runner'
module CsBuilder
  module Git

    module GitHelper extend CsBuilder::ShellRunner

      @@log = Log.get_logger('git-helper')

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
        sha = run_git(path, "rev-parse --short HEAD")
        raise "no sha" if sha.nil? or sha.empty?
        sha.strip
      end

      def self.has_tag?(path, tag)
        `#{base_git(path)} tag --contains #{tag}`
        $?.to_i == 0
      end

      def self.clone_repo(path, git_repo, branch)
        @@log.info "path: #{path}, branch: #{branch}"
        FileUtils.mkdir_p(path, :verbose => true ) unless File.exists?(path)
        shell_run("git clone #{git_repo} #{path}") unless File.exists?(File.join(path, ".git"))
        @@log.debug "checkout #{branch}"
        
        run_git(path, "checkout #{branch}")
        run_git(path, "branch --set-upstream-to=origin/#{branch} #{branch}")

        if File.exists?(File.join(path, ".gitmodules"))
          in_dir(path) {
            @@log.debug "Init the submodules in #{path}"
            shell_run("git submodule init")
          }
        end
      end

      def self.update_repo(path, branch)
        @@log.info "[update_repo] path: #{path}, branch: #{branch}"
        @@log.debug "reset hard to #{branch}"
        
        run_git(path, "clean -fd")
        run_git(path, "reset --hard HEAD")
        run_git(path, "checkout #{branch}")
        run_git(path, "fetch origin #{branch}")
        run_git(path, "reset --hard origin/#{branch}")

        if File.exists? "#{path}/.gitmodules"
          in_dir(path){
            @@log.debug "update all the submodules in #{path}"
            shell_run("git submodule foreach git clean -fd")
            shell_run("git pull --recurse-submodules")
            shell_run("git submodule update --recursive")
          }
        end
      end

      private 

      def self.base_git(path)
        "git --git-dir=#{path}/.git --work-tree=#{path}"
      end

      def self.run_git(path, cmd) 
        full_cmd = "#{base_git(path)} #{cmd}"
        puts "full: #{full_cmd}"
        out = shell_run(full_cmd)
        puts "out: #{}"
        out
      end

    end
  end
end
