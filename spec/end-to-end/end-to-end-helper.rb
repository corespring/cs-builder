require_relative '../integration/helpers/integration'
require 'cs-builder/log/logger'

module Helpers
  module EndToEnd

    include Helpers::Integration

    CsBuilder::Log.set_config({"default" => "DEBUG", "slug-builder" => "DEBUG"})
    
    def build_deploy_and_load_example(name, mk_opts, deploy_opts, stack)

      heroku_app = ENV["TEST_HEROKU_APP"]

      config_dir = "spec/tmp/#{name}"

      if !stack
        stack = "cedar-14"
      end      

      FileUtils.rm_rf(config_dir)

      config_dir = "spec/tmp/#{name}" 
      tmp_project = copy_project_to_tmp(name) 

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

      build_result = BuildFromFile.new(config_dir).run(file_opts)

      puts "build_result: #{build_result}"

      paths = Paths.new(config_dir, "org", name, "master")

      slug_path = File.expand_path(File.join(paths.slugs, "build-1.tgz"))
      binaries_path = File.expand_path(File.join(paths.binaries, "build-1.tgz"))

      make_slug_opts = {
        :template => template,
        :binary => binaries_path,
        :output => slug_path
      }

      out = MakeSlug.new(config_dir).run(make_slug_opts)
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
