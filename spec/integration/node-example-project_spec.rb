require_relative './helpers'

describe CsBuilder do

  include Helpers::Integration

  clean_up = true

  it "should work" do
  	
    result = build_deploy_and_load_example("node-0.10.20", "", ["index.js"], "node-0.10.20", "cedar-14", clean_up)
    result.should eql("Hello World\n")
  end

  it "should clean up slug folder" do
  	
  	name = "node-0.10.20"
  	path = returnPath(name)
  	cleanup_after_deploy(clean_up, path)

    if clean_up
      expect(Dir.entries(path).size <= 2).to be_truthy
    else
      expect(Dir.entries(path).size <= 2).to be_falsey
    end
  end

end