require 'cs-builder/cmds/build'
require 'cs-builder/cmds/make-slug'
require 'cs-builder/models/paths'
require 'cs-builder/heroku/heroku-deployer'
require 'cs-builder/heroku/slug-helper'
require 'cs-builder/log/logger'
require 'dotenv'
require 'tmpdir'

include CsBuilder::Commands
include CsBuilder::Models
include CsBuilder::Heroku
include CsBuilder::Heroku::SlugHelper

module Helpers
  module Integration

    @@log = CsBuilder::Log.get_logger("integration-helper")

    Dotenv.load

    def default_config_dir
      this_dir = File.expand_path(File.dirname(__FILE__))
     "#{this_dir}/../../../.default-config/."
    end

    def get_example_project(project, config_dir: default_config_dir)
      File.expand_path(File.join(config_dir, "example-projects", project))
    end

    def copy_example_project(project, to, config_dir: default_config_dir)
      project_path = get_example_project(project)
      out = File.join(to, project)
      FileUtils.mkdir_p(File.dirname(to))
      FileUtils.cp_r(project_path, to, :verbose => @@log.debug?)
      out
    end

    def copy_project_to_tmp(project)
      tmp_dir = Dir.mktmpdir("cs-builder-integration-tests", :verbose => @@log.debug?)
      copy_example_project(project, tmp_dir)
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
      @@log.info "?? -> #{out}"
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
      new_dir = copy_project_to_tmp(name) 
      {:config_dir => config_dir, :project_dir => new_dir}
    end

  end
end
