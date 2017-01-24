require 'cs-builder/models/paths'

include CsBuilder::Models

describe CsBuilder::Models::Paths do 
  
  before(:all) do 
    @p = Paths.new("/", "org", "repo", "branch")
  end

  describe "artifacts" do 
    
    it "should return the path to artifacts" do 
      @p.artifacts.should eql("/artifacts/org/repo")
    end
  end

  describe "repo" do 
    it "should return the repo path" do 
      @p.repo.should eql("/repos/org/repo/branch")
    end
  end
  
  describe "binaries" do 
    it "should return the  binaries path" do 
      @p.binaries.should eql("/binaries/org/repo/branch")
    end
  end
  
  describe "lock_file" do 
    it "should return the  lock_file path" do 
      @p.lock_file("file").should eql("/locks/org/repo/branch/file.lock")
    end
  end
  
  describe "slugs" do 
    it "should return the  slugs path" do 
      @p.slugs.should eql("/slugs/org/repo/branch")
    end
  end
end