require 'cs-builder/templates'
require 'cs-builder/log/logger'
require_relative './helpers'

describe CsBuilder::Templates do 

  CsBuilder::Log.set_config({
    "shell" => "DEBUG",
    "spec" => "DEBUG"
    })
  
  include Helpers::Integration

  describe "install_template" do 

    before(:all) do 
      @log = CsBuilder::Log.get_logger("spec")
    end

    before(:each) do 
      dir = create_tmp_config_dir("templates_spec")
      @templates_dir = File.join(dir, "templates")
      @templates = CsBuilder::Templates.new(@templates_dir)
    end

    it "installs the template", :install => true do 
      path = @templates.get_archive_path("node-0.10.20")
      @log.debug("path: #{path}")
      path.should eql(File.join(@templates_dir, "built", "node-0.10.20.tgz"))
    end
  end
end