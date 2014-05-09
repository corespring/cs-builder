require 'cs-builder/cmds/build'
require 'cs-builder/cmds/make-slug'
require 'cs-builder/models'
require 'cs-builder/heroku-deployer'
require 'dotenv'

include CsBuilder::Commands
include CsBuilder::Models
include CsBuilder

# Tests
# - a build of binaries
# - installation of a template with a formula
# - slug creation
# - slug deployment to heroku

describe CsBuilder do 

    Dotenv.load

    def add_default_config(path)
      FileUtils.cp_r(".default-config", path, :verbose => true) 
    end

    it "should work" do 

      heroku_app = ENV["TEST_HEROKU_APP"] 

      include CsBuilder::Models::SlugHelper

      config_dir = "spec/tmp/node-example-config"
      
      FileUtils.rm_rf(config_dir)
      
      add_default_config(config_dir)

      file_opts = {
        :external_src => File.expand_path(File.join(config_dir, "example-projects", "node-0.10.20")),
        :org => "org",
        :repo => "node-example",
        :branch => "master",
        :cmd => "",
        :uid => "build-1",
        :build_assets => ["index.js"]
      }

      build_result = BuildFromFile.new("DEBUG", config_dir).run(file_opts) 

      puts "build_result: #{build_result}"

      paths = Paths.new(config_dir, "org", "node-example", "master")

      slug_path = File.expand_path(File.join(paths.slugs, "build-1.tgz"))
      binaries_path = File.expand_path(File.join(paths.binaries, "build-1.tgz"))

      make_slug_opts = {
        :template => "node-0.10.20",
        :binary => binaries_path,
        :output => slug_path
      }

      out = MakeSlug.new("DEBUG", config_dir).run(make_slug_opts)
      puts "MakeSlug result: #{out}"
      deployer = HerokuDeployer.new
      # TODO - make heroku app configurable
      deployer.deploy(slug_path, SlugHelper.processes_from_slug(slug_path), heroku_app )


      # give the app some time to boot up
      sleep 10

      result = RestClient.get("http://#{heroku_app}.herokuapp.com")

      result.should eql("Hello World\n")
    end

end