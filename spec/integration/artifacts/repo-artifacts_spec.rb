require 'cs-builder/artifacts/repo-artifacts'

include CsBuilder::Artifacts

describe CsBuilder::Artifacts::RepoArtifacts do 

  describe "initialize" do

    it "should init" do 
      a = RepoArtifacts.new("", "", "", "")
      a.should_not be_nil 
    end
  end
end