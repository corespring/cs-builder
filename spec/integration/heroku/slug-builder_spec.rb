require 'cs-builder/heroku/slug-builder'
require 'cs-builder/log/logger'
require 'cs-builder/io/archive'
require 'cs-builder/templates'
require 'tmpdir'
require_relative '../helpers'

describe CsBuilder::Heroku::SlugBuilder do 

  include Helpers::Integration

  CsBuilder::Log.set_config({
    "slug-builder" => "DEBUG",
    "archive" => "DEBUG",
    "shell" => "DEBUG",
    "spec" => "DEBUG"
    })

  def create_node_artifact_from_example(name)
    dir = File.join(default_config_dir, "example-projects", name)
    out = File.join(Dir.mktmpdir("slug_builder_"), "node-app.tgz")
    CsBuilder::IO::Archive.create(dir, out, ["Procfile", "index.js"])
    out
  end

  before(:all) do 
    @log = CsBuilder::Log.get_logger("spec")
  end
  
  before(:all) do 
    dir = create_tmp_config_dir("slug_builder_spec")
    @templates_dir = File.join(dir, "templates")
    @templates = CsBuilder::Templates.new(@templates_dir)
    @node_archive = @templates.get_archive_path("node-0.10.20")
  end
  
  describe "run" do
    it "should build a slug" do
      node_app = create_node_artifact_from_example("node-0.10.20")
      @log.debug("node app: #{node_app}")
      tmp = Dir.mktmpdir("slug_builder_")
      out_path = File.join(tmp, "out.tgz")
      slug_path = CsBuilder::Heroku::SlugBuilder.mk_slug(@node_archive, node_app, out_path)
      File.exists?(slug_path).should eql(true)
    end
  end
end