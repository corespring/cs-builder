require 'cs-builder/heroku/heroku-deployer'
require 'platform-api'

include CsBuilder::Heroku

describe HerokuDeployer do


  before(:each) do

    CsBuilder::Log.set_config({"heroku-deployer" =>"debug"})
    File.stub(:exists?){ true }
    File.stub(:expand_path).and_return("path")
    @desc = HerokuDescription.new("app", "hash", "tag")
    @heroku = double 

    @slug = double 
    @slug.stub(:info) {
      {"commit" => "1", "commit_description" => @desc.json_string}
    }
    
    @slug.stub(:create).with("app", anything()){
      {"blob" => { "url" => "url" }, "id" => "slug-id-1"}
    }

    @heroku.stub(:slug){@slug}

    @release = double 
    @release.stub(:create).with("app", anything()){ {} }

    @release.stub(:list){[
      {"version" => 1, "slug" => {"id" => "1"}}
    ]}
    
    @heroku.stub(:release){ @release }

    platform = double 
    platform.stub(:connect_oauth) {@heroku}
    stub_const("::PlatformAPI", platform)

    @deployer = HerokuDeployer.new
    @deployer.stub(:`) do |cmd|
       cmd
    end
  end

  it "should not be nil when constructed" do 
    @deployer.should_not be_nil
  end


  describe "already_deployed" do 
    it "should return true if the descriptions match" do
      new_desc = HerokuDescription.new("app", "hash", "tag")
      deployed = @deployer.already_deployed('app', 'hash', new_desc.json_string)
      deployed.should be(true)
    end
    
    it "should return false if the descriptions don't match" do
      new_desc = HerokuDescription.new("app", "hash-new", "tag")
      deployed = @deployer.already_deployed('app', 'hash', new_desc.json_string)
      deployed.should be(false)
    end
    
    it "should return false if the new description is invalid" do
      deployed = @deployer.already_deployed('app', 'hash', "blah")
      deployed.should be(false)
    end
    
    it "should return false if both are nil" do
      @slug.stub(:info) {
        {"commit" => "1", "commit_description" => nil }
      }

      deployed = @deployer.already_deployed('app', 'hash', nil)
      deployed.should be(false)
    end
    
    it "should return false if the new description is valid and the current isn't" do
      @slug.stub(:info) {
        {"commit" => "1", "commit_description" => "invalid" }
      }

      deployed = @deployer.already_deployed('app', 'hash', "blah")
      deployed.should be(false)
    end
  end

  context "deploy" do 

    it "should do nothing if the description matches" do 
      @deployer.deploy({}, {}, 'app', 'hash', @desc.json_string, 'stack', force: false)      
      @heroku.should_not receive(:create)      
    end

    it "should call create if the descriptions don't match" do 
      new_desc = HerokuDescription.new("new-app", "hash", "tag")
      @deployer.deploy({}, {}, 'app', 'hash', new_desc.json_string, 'stack', force: false)      

      payload = {
        :process_types => {},
        :commit => "hash",
        :commit_description => new_desc.json_string, 
        :stack => "stack"
      }

      @heroku.slug.should have_received(:create).with("app", payload)
      @heroku.release.should have_received(:create).with("app", {"slug" => "slug-id-1"})
    end

  end

end
