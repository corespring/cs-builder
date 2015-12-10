require_relative './core-command'
require_relative '../git/git-parser'
require_relative '../git/git-helper'
require_relative '../models/paths'
require_relative '../io/safe-file-removal'
require_relative '../heroku/slug-from-template'

module CsBuilder
  module Commands

    class MakeSlug < CoreCommand

      include CsBuilder::IO::SafeFileRemoval

      def initialize(config_dir, log_name: 'make_slug')
        super(log_name, config_dir)
      end

      def run(options)
        @log.info "[run] MakeSlug..."
        @log.debug "[run] options: #{options}"
        template = options[:template]
        binary = options[:binary]
        output = options[:output]
        slug_path = CsBuilder::Heroku::SlugFromTemplate.mk_slug(
          binary,
          output,
          template,
          File.join(@config_dir, "templates"),
          options[:force])
        safely_remove_all_except(slug_path)
        output
      end
    end

    class MakeFileSlug < MakeSlug

      include CsBuilder::Models

      def initialize(config_dir)
        super(config_dir, log_name: 'make_file_slug')
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

      def initialize(config_dir)
        super(config_dir, log_name: 'make_git_slug')
      end

      def build_slug(options)

        @log.debug("options: #{options}")
        @log.debug("options[:org].nil? #{options[:org].nil?}") 
        git = options[:git]
        org = options.has_key?(:org) ? options[:org] : GitUrlParser.org(git)
        repo = options.has_key?(:repo) ? options[:repo] : GitUrlParser.repo(git)
        branch = options[:branch]
        paths = Paths.new(@config_dir, org, repo, branch)
        uid = git_uid(paths.repo) 

        @log.debug "org: #{org}, repo: #{repo}, branch: #{branch}"

        raise "uid is nil" if uid.nil?

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
