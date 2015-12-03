require 'cs-builder/heroku/heroku-deployer'

include CsBuilder::Heroku

describe HerokuDeployer do


  before(:each) do


    File.stub(:exists?){ true }
    File.stub(:expand_path).and_return("path")
    RestClient::Request = double
    response = double
    response.stub(:code) { 200 }
    response.stub(:body) { {:ok => true } }
    RestClient::Request.stub(:execute) {  
      JSON.generate(
        { :id=> "id", :blob => {:url => "blob-url" }}
      )
    }

    @deployer = HerokuDeployer.new
    
    @deployer.stub(:`) do |cmd|
      cmd
    end
  end

  it "should not be nil when constructed" do 
    expect(@deployer).not_to be_nil
  end
  
  it "should call create_slug with the appropriate payload", :spy => true do 
    @deployer.deploy({}, {}, 'app', 'hash', 'description', 'stack')

    data = {
      :process_types => {},
      :commit => "hash",
      :commit_description => "description", 
      :stack => "stack"
    }

    expect(RestClient::Request).to have_received(:execute).with(hash_including(:payload => data)) #.with({})
  end

end
