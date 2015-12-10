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

    def create_tmp_config_dir(name)
      tmp_path = "spec/tmp/#{name}"
      FileUtils.rm_rf(tmp_path)
      FileUtils.cp_r(default_config_dir, tmp_path)
      tmp_path
    end
    
    def prepare_tmp_project(name) 
      FileUtils.rm_rf("spec/tmp/#{name}")
      config_dir = "spec/tmp/#{name}" 
      new_dir = copy_project_to_tmp(default_config_dir, name) 
      {:config_dir => config_dir, :project_dir => new_dir}
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


  end
end
