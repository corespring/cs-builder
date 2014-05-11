require_relative './helpers'

describe CsBuilder do

  include Helpers::Integration

  it "should work" do
    result = build_deploy_and_load_example("node-0.10.20", "", ["index.js"], "node-0.10.20")
    result.should eql("Hello World\n")
  end

end
