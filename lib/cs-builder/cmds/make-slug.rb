require_relative './core-command'
require_relative '../git/git-parser'
require_relative '../git/git-helper'
require_relative '../models/paths'
require_relative '../io/safe-file-removal'
require_relative '../io/file-lock'

module CsBuilder
  module Commands

    class MakeSlug < CoreCommand

      include CsBuilder::Io::SafeFileRemoval
      include CsBuilder::Io::FileLock

      def initialize(level, config_dir, log_name: 'make_slug')
        super(log_name, level, config_dir)
      end

      def run(options)
        @log.info "running MakeSlug"
        template = options[:template]
        init_template(template)
        build_slug(options)
      end

      def init_template(name)
        if !File.exists?(template_archive(name))
          @log.info "need to install the template for #{name}.. please wait..."
          install_template(name)
        else
          @log.debug("Formula already exists for #{name}")
        end
      end

      def formula(name)
        File.expand_path(File.join(@config_dir, "templates", "formulas", name))
      end

      def template_archive(name)
        File.join(@config_dir, "templates", "built", "#{name}.tgz")
      end

      def install_template(name)
        @log.debug "need to install template, looking for a formla for #{name}"
        script = formula("#{name}.formula")
        raise "No formula found for #{script}" unless File.exists? script
        mkdir_if_needed(File.join(@config_dir, "templates", "built"))
        in_dir(File.dirname(script)){
          File.chmod(0755, "#{name}.formula")
          @log.debug "running formula: #{name}.formula - this will install the template for #{name} - this is a one-time process ... please wait"
          run_cmd "./#{name}.formula ../built"
        }
      end

      def build_slug(options)
        @log.debug "[build_slug] options: #{options}"
        template = options[:template]
        binary = options[:binary]
        archive = template_archive(template)
        raise "Archive doesn't exist: #{archive}" unless File.exists? archive
        output = options[:output]
        output_dir = output.gsub(".tgz", "")
        app_path = File.join(output_dir, "app")

        @log.debug "binary path to add to tar: #{binary}"

        if File.exists?(output) and !options[:force]
          @log.info "File #{output} already exists"
          output
        else
          with_file_lock(binary){
            FileUtils.mkdir_p app_path, :verbose => true
            @log.debug "extract #{archive} -> #{app_path}"
            run_shell_cmd("tar xvf #{archive} -C #{app_path}")
            @log.debug "extract #{binary} -> #{app_path}"
            run_shell_cmd("tar xvf #{binary} -C #{app_path}")
            @log.debug "compress folder to a new archive: #{output}"
            #Note: the './app' is significant here
            run_shell_cmd("tar czvf #{output} -C #{output_dir} ./app")
            FileUtils.rm_rf output_dir, :verbose => true
          }
        end

        remove_old_slugs(output)
        output
      end

      def remove_old_slugs(latest_slug)
        safely_remove_all_except(latest_slug)
      end

    end

    class MakeFileSlug < MakeSlug

      include CsBuilder::Models

      def initialize(level, config_dir)
        super(level, config_dir, log_name: 'make_file_slug')
      end

      def build_slug(options)
        org = options[:org]
        repo = options[:repo]
        branch = options[:branch]
        paths = Paths.new(@config_dir, org, repo, branch)
        sha = options[:uid]

        @log.debug "org: #{org}, repo: #{repo}, branch: #{branch}"

        prepped = options.merge(
          {
            :template => options[:template],
            :binary => File.join(paths.binaries, "#{sha}.tgz"),
            :output => File.join(paths.slugs, "#{sha}.tgz"),
        })
        super(prepped)
      end
    end

    class MakeGitSlug < MakeSlug

      include CsBuilder::Models
      include CsBuilder::Git::GitHelper
      include CsBuilder::Git

      def initialize(level, config_dir)
        super(level, config_dir, log_name: 'make_git_slug')
      end

      def build_slug(options)
        git = options[:git]
        org = options[:org] or GitUrlParser.org(git)
        repo = options[:repo] or GitUrlParser.repo(git)
        branch = options[:branch]
        paths = Paths.new(@config_dir, org, repo, branch)
        uid = commit_tag(paths.repo) or commit_hash(paths.repo)

        @log.debug "org: #{org}, repo: #{repo}, branch: #{branch}"

        prepped = options.merge(
          {
            :template => options[:template],
            :binary => File.join(paths.binaries, "#{uid}.tgz"),
            :output => File.join(paths.slugs, "#{uid}.tgz"),
        })
        super(prepped)
      end

    end
  end
end
