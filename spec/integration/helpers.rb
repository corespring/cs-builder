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

    def add_default_config(path)
      FileUtils.cp_r(".default-config", path, :verbose => true)
    end

    def build_deploy_and_load_example(name, cmd, assets, template, stack, clean_up)

      heroku_app = ENV["TEST_HEROKU_APP"]

      config_dir = "spec/tmp/#{name}"

      if !stack
        stack = "cedar-14"
      end      

      if !clean_up
        clean_up = false
      end      

      FileUtils.rm_rf(config_dir)

      add_default_config(config_dir)

      file_opts = {
        :external_src =>
          File.expand_path(
            File.join(config_dir, "example-projects", name)
        ),
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
      deployer.deploy(slug_path, SlugHelper.processes_from_slug(slug_path), heroku_app, file_opts[:uid], stack)

      # give the app some time to boot up
      sleep 4
      RestClient.get("http://#{heroku_app}.herokuapp.com")

      case cleanup
      when true
        safely_remove(slug_path)
        safely_remove(binaries_path)
      end
    end

  end
end
