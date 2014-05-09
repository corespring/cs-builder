require 'thor'

Dir[File.dirname(__FILE__) + '/cmds/*.rb'].each {|file| require file }

module CsBuilder

  include Commands

  class CLI < Thor

    desc "build-from-git", "clone if needed, update, build and create an archive"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :build_assets, :type => :array, :required => true
    option :cmd, :type => :string, :default => "play clean update compile stage"
    option :log_level, :type => :string, :default => "INFO"
    option :force, :type => :boolean, :default => false
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    long_desc <<-LONGDESC
    `build-from-git` will clone if needed, build and create an archive of `build_assets`.
    --

    * git clone the project/branch if needed
    * update the project
    * run the `cmd` which is expected to build the project
    * create an archive here:
     -- binaries/org/repo/branch/commit_hash.tgz
    * return the path to the archive on completion.
 
  LONGDESC
    def build_from_git
      puts options
      cmd = Commands::BuildFromGit.new(options[:log_level], options[:config_dir])
      out = cmd.run(options)
      puts out
    end

    desc "build-from-file", "copy a local project, build and create an archive"
    option :external_src, :type => :string, :required => true
    option :org, :type => :string, :required => true
    option :repo, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :build_assets, :type => :array, :required => true
    option :cmd, :type => :string, :default => ""
    option :uid, :type => :string
    option :log_level, :type => :string, :default => "INFO"
    option :force, :type => :boolean, :default => false
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    long_desc <<-LONGDESC
    `build-from-file` will copy a local folder, build and create an archive of `build_assets`.
    --

    It uses the org/repo/branch naming convention so these need to be passed in as params.

    steps
    * copy the folder to org/name/branch (you need to specify these) 
    * run the `cmd` which is expected to build the project
    * create an archive here:
     -- binaries/org/repo/branch/uid.tgz
    * return the path to the archive on completion.
 
    LONGDESC

    def build_from_file
      puts options
      cmd = Commands::BuildFromGit.new(options[:log_level], options[:config_dir])
      out = cmd.run(options)
      puts out
    end

    desc "remove-config", "remove ~/.cs-build config folder (Can't undo!!)"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def remove_config
      Commands::RemoveConfig.new(options[:config_dir]).run
    end

    desc "git-slug", "make a slug"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :sha, :type => :string, :required => false
    option :template, :type => :string, :default => "jdk-1.7"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
     long_desc <<-LONGDESC
    `git-slug` will create a heroku compatible slug using binaries and a slug template. 
    --
    
    steps: 
    * get the commit_hash from the source repo 
    * check to see if there is a binary with that commith_hash in 'repos'
    * check to see if there is a template ready
    ** if not install the template using the formula
    * expand the template and binaries to one folder
    * compress archive into a heroku compatible slug
    * return the path to the slug  
    LONGDESC

    def git_slug
      cmd = Commands::MakeGitSlug.new(options[:log_level], options[:config_dir])
      out = cmd.run(options)

      puts "Done: #{out}"
    end

    desc "list-slugs", "list all slugs"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :sha, :type => :string, :required => false
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def list_slugs
      cmd = Commands::ListSlugs.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end

    desc "remove template", "remove template"
    option :template, :type => :string, :required => true
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def remove_template 
      cmd = Commands::RemoveTemplate.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end

    desc "list templates", "list installed templates"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def list_templates
      cmd = Commands::ListTemplates.new(options[:log_level], options[:config_dir])
      cmd.run(options)
    end

    desc "heroku-deploy-slug", "deploy a slug"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :heroku_app, :type => :string, :required => true 
    option :commit_hash, :type => :string
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    option :log_level, :type => :string, :default => "INFO"
    def heroku_deploy_slug
      cmd = Commands::HerokuDeploySlug.new(options[:log_level], options[:config_dir])
      puts cmd.run(options)
    end



=begin
    desc "list-slugs", "list slugs for git+branch"
    option :git, :type => :string, :required => true
    option :branch, :type => :string, :required => true
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def list_slugs
      cmd = Commands::ListSlugs.new
      puts cmd.run(options)
    end

    desc "slug-templates", "list slug templates"
    option :config_dir, :type => :string, :default => File.expand_path("~/.cs-builder")
    def slug_templates 
      cmd = Commands::SlugTemplates.new
      puts cmd.run(options)
    end
=end
  end
end
