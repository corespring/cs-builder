require 'log4r'
require 'log4r/outputter/datefileoutputter'
require_relative './git-parser' 
module CsBuilder

  module Commands

    class CoreCommand

      @config_dir = File.expand_path("~/.cs-builder")

      Log4r.define_levels(*Log4r::Log4rConfig::LogLevels)

      def initialize(name, level, config_dir, init: true)

        @config_dir = config_dir
        log_level = str_to_log_level(level)
        @log = Log4r::Logger.new(name) 
        @log.outputters << Log4r::StdoutOutputter.new('log_stdout') #, :level => Log4r::WARN )
        @log.level = log_level 
        @log.debug("config_dir: #{@config_dir}")
        init_build_dir if init
      end

      protected

      def run_cmd(cmd)
        @log.debug "[run] -> #{cmd}"
        IO.popen(cmd) do |io|
          while line = io.gets
            # the heroku-helper adds this to reset the ansi command - strip it
            cleaned = line.chomp
            puts "#{cleaned}" unless cleaned == nil or cleaned.empty?
          end
            io.close
            raise "An error occured" if $?.to_i != 0
        end
      end

      def in_dir(dir)
        current = File.expand_path(Dir.pwd)
        Dir.chdir(dir)
        @log.debug("[in_dir] current dir #{Dir.pwd}")
        yield
        Dir.chdir(current)
        @log.debug("[in_dir] back to: #{Dir.pwd}")
      end

      private 

      def init_build_dir
        if(File.exists? @config_dir)
          @log.debug "config dir already exists - skip initialisation"
        else 
          default_config = "#{File.expand_path(File.dirname(__FILE__))}/../../.default-config/."
          FileUtils.mkdir(@config_dir)
          FileUtils.cp_r(default_config, @config_dir)
        end
      end

      def str_to_log_level(s)
        case s.upcase
        when "FATAL" 
          return 5 
        when "ERROR" 
          return 4 
        when "WARN" 
          return 3 
        when "INFO" 
          return 2
        when "DEBUG"
          return 1
        else 
          return 2 
        end
      end

    end

    class RemoveConfig < CoreCommand
      
      def initialize(config_dir)
        super('remove_config', 'DEBUG', config_dir, init: false)
      end

      def run
        FileUtils.rm_rf(@config_dir)
      end

    end

    class MakeSlug < CoreCommand


      def initialize(level, config_dir)
        super('make_slug', level, config_dir)
      end

      def run(options)
        @log.info "running MakeSlug"
        template = options[:template]
        init_template(template) 
        build_slug(options)
      end

      protected

      def init_template(name)
        if !File.exists?(installed_path(extra: "/#{name}.tgz"))
          @log.info "need to install the template for #{name}.. please wait..."
          install_template(name)
        else 
          @log.debug("Formula already exists for #{name}")
        end
      end

      def install_template(name)

        @log.debug "need to install template, looking for a formla for #{name}"
        script = formula_path(extra: "/#{name}.formula") 
        raise "No formula found for #{script}" unless File.exists? script 
        in_dir(formula_path){
          File.chmod(0755, "#{name}.formula")
          @log.debug "running formula.. please wait"
          run_cmd "./#{name}.formula ../built"
        }
      end

      def build_slug(options)
      
      end

      def installed_path(extra: "")
        "#{@config_dir}/templates/built" << extra
      end

      def formula_path(extra: "")
        "#{@config_dir}/templates/formulas" << extra
      end
    end

    class BaseBuild < CoreCommand

    end

    class BuildFromGit < BaseBuild 

      def initialize(level, config_dir)
        super('build-from-git', level, config_dir)
      end

      def run(options)
        git = options[:git]
        branch = options[:branch]
        cmd = options[:cmd]
        binaries = options[:binaries]
        org = GitParser.org(git)
        repo = GitParser.repo(git)
        path = repo_path(org, repo, branch)
        binary_path = binaries_path(org, repo, branch)
        @log.debug("path: #{path}") 
        @log.debug("git: #{git}, branch: #{branch}, cmd: #{cmd}")
        install_repo(git, branch, path) unless File.exists?(path) 
        update_repo(branch, path)
        sha = `git --git-dir=#{path}/.git --work-tree=#{path} rev-parse --short HEAD`.strip
        raise "no sha" if sha.nil? or sha.empty?

        if File.exists?( archive_path(binary_path, sha, suffix: ".tgz"))
          @log.info("This sha has already been built #{archive_path(binary_path, sha, suffix: ".tgz")}")
          0
        else 
          @log.debug("sha: #{sha}, binaries path: #{binary_path}")
          build_app(path, cmd)
          prepare_binaries(path, binary_path, sha, binaries)
        end
      end

      private 

      def repo_path(org, repo, branch)
        "#{@config_dir}/repos/#{org}/#{repo}/#{branch}"
      end

      def binaries_path(org, repo, branch)
        "#{@config_dir}/binaries/#{org}/#{repo}/#{branch}"
      end

      def archive_path(binary_path, sha, suffix: "")
        "#{binary_path}/#{sha}" << suffix
      end

      def install_repo(git, branch, path)
        FileUtils.mkdir_p(path, :verbose => true )
        @log.debug "clone #{git}"
        `git clone #{git} #{path}`
        @log.debug "checkout #{branch}"
        `git --git-dir=#{path}/.git --work-tree=#{path} checkout #{branch}`

        if File.exists? "#{path}/.gitmodules" 
          in_dir(path) {
          @log.debug "Init the submodules in #{path}"
          `git submodule init`
          }
        end
      end

      def update_repo(branch, path)
        @log.debug "reset hard to #{branch}"
        `git --git-dir=#{path}/.git --work-tree=#{path} reset --hard HEAD`
        `git --git-dir=#{path}/.git --work-tree=#{path} pull origin #{branch}`
        if File.exists? "#{path}/.gitmodules" 
          in_dir(path){
            @log.debug "update all the submodules in #{path}"
            `git pull --recurse-submodules`
            `git submodule update --recursive`
          }
        end
      end

      def build_app(path, cmds)
        in_dir(path){
          @log.debug( "run: #{cmds}")
          run_cmd cmds
        }
      end

      def prepare_binaries(src_path, out_path, sha, binaries)
        @log.debug("[prepare_binaries] src: #{src_path}, #{out_path}, #{binaries}")
        target = archive_path(out_path, sha)
        @log.debug("target: #{target}")
        FileUtils.mkdir_p target

        binaries.each{ |b|
          from = "#{src_path}/#{b}"
          to = "#{target}/#{b}"
          FileUtils.cp_r(from, to, :verbose => true)
        }

        system("tar", "czvf", "#{target}.tgz", "-C", target, ".",
                 [:out, :err] => "/dev/null") 

        FileUtils.rm_rf(target, :verbose => true) 
        "#{target}.tgz"
      end

    end
  end
end

