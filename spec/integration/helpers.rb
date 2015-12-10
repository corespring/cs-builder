require 'cs-builder/cmds/build'
require 'cs-builder/cmds/make-slug'
require 'cs-builder/models/paths'
require 'cs-builder/heroku/heroku-deployer'
require 'cs-builder/heroku/slug-helper'
require 'dotenv'

include CsBuilder::Commands
include CsBuilder::Models
include CsBuilder::Heroku
include CsBuilder::Heroku::SlugHelper

module Helpers
  module Integration

    Dotenv.load

    def default_config_dir
      this_dir = File.expand_path(File.dirname(__FILE__))
     "#{this_dir}/../../.default-config/."
    end

    def add_default_config(path)
      FileUtils.cp_r(default_config_dir, path, :verbose => true)
    end

    def copy_project_to_tmp(config_dir, project)
      path = File.expand_path(File.join(config_dir, "example-projects", project))
      tmp_dir = Dir.mktmpdir("cs-builder-integration-tests")
      FileUtils.cp_r(path, tmp_dir)
      out = File.join(tmp_dir, project)
      raise "cp failed for #{path} -> #{out}" unless File.exists?(out)
      out
    end

    def run_shell_cmds(dir, cmds)

      pwd = Dir.pwd
      script = <<-EOF
      #!/usr/bin/env bash
      #{cmds}
      EOF
      script_path  = File.join(dir, "run.sh")
      File.open(script_path, 'w') { |file| file.write(script) }
      FileUtils.chmod(0755, script_path)
      Dir.chdir(dir)
      out = `./run.sh`
      Dir.chdir(pwd)
      puts "?? -> #{out}"
      out
    end
    
    def build_git(name, shell_cmds, formula)
      FileUtils.rm_rf("spec/tmp")
      config_dir = "spec/tmp/#{name}" 
      new_dir = copy_project_to_tmp(default_config_dir, name) 

      cmd_result = run_shell_cmds(new_dir, shell_cmds)

      puts "new dir: #{new_dir}"

      opts = {
        :git => new_dir,
        # override org and repo
        :org => "org",
        :repo =>  File.basename(new_dir),
        :branch => "master",
        :cmd => "",
        :build_assets => ["index.js"]  
      }

      binary_result = BuildFromGit.new("DEBUG", config_dir).run(opts)

      mk_slug_opts = {
        :git => new_dir,
        :org => "org",
        :repo => File.basename(new_dir),
        :branch => "master",
        :template => formula 
      }

      slug_result = MakeGitSlug.new("DEBUG", config_dir).run(mk_slug_opts) 

      { 
        :cmd_result => cmd_result,
        :binary_result => binary_result, 
        :slug_result => slug_result 
      }

    end

    def build_deploy_and_load_example(name, cmd, assets, template, stack)

      heroku_app = ENV["TEST_HEROKU_APP"]

      config_dir = "spec/tmp/#{name}"

      if !stack
        stack = "cedar-14"
      end      

      FileUtils.rm_rf(config_dir)

      config_dir = "spec/tmp/#{name}" 
      tmp_project = copy_project_to_tmp(default_config_dir, name) 

      puts "tmp_project: #{tmp_project}"

      file_opts = {
        :external_src => tmp_project,
        :org => "org",
        :repo => name,
        :branch => "master",
        :cmd => cmd,
        :uid => "build-1",
        :build_assets => assets
      }

      build_result = BuildFromFile.new("DEBUG", config_dir).run(file_opts)

      puts "build_result: #{build_result}"

      paths = Paths.new(config_dir, "org", name, "master")

      slug_path = File.expand_path(File.join(paths.slugs, "build-1.tgz"))
      binaries_path = File.expand_path(File.join(paths.binaries, "build-1.tgz"))

      make_slug_opts = {
        :template => template,
        :binary => binaries_path,
        :output => slug_path
      }

      out = MakeSlug.new("DEBUG", config_dir).run(make_slug_opts)
      puts "MakeSlug result: #{out}"
      deployer = HerokuDeployer.new
      # TODO - make heroku app configurable
      deployer.deploy(
        slug_path, 
        SlugHelper.processes_from_slug(slug_path), 
        heroku_app, 
        file_opts[:uid], 
        "my new app",
        stack)

      # give the app some time to boot up
      sleep 4
      url = "http://#{heroku_app}.herokuapp.com"
      puts "Ping the url: #{url}"
      RestClient.get(url)
    end

  end
end
