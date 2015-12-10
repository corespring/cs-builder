require 'cs-builder/artifacts/repo-artifacts'

include CsBuilder::Artifacts

describe CsBuilder::Artifacts::RepoArtifacts do 

  describe "initialize" do

    it "should init" do 
      a = RepoArtifacts.new("", "", "", "")
      a.nil? should eql(false)
    end
  end
end