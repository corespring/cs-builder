require_relative './end-to-end-helper'

describe CsBuilder do

  include Helpers::EndToEnd

  it "should work" do
    result = build_deploy_and_load_example("play-221", "play stage", ["target"], "jdk-1.7", "cedar-14")
    result.should eql("I'm a simple play app")
  end

end
