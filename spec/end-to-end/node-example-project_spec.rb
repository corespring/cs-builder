require_relative './end-to-end-helper'

describe CsBuilder do

  include Helpers::EndToEnd

  it "should work" do
    result = build_deploy_and_load_example("node-0.10.20", "echo \"noop\"", ["index.js"], "node-0.10.20", "cedar-14")
    result.should eql("Hello World\n")
  end

end
