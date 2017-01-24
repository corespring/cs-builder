require 'cs-builder/git/repo'

include CsBuilder::Git

describe CsBuilder::Git::HashAndTag do 


  describe "to_simple" do 

    it "should create a string with hash and tag" do 
      HashAndTag.new("hash", tag = "tag").to_simple.should eql("tag-hash")
    end
    
    it "should create a string with hash only" do 
      HashAndTag.new("hash").to_simple.should eql("hash")
    end
  end

  describe "self.from_simple" do 
    it "self.from_simple with hash and tag" do 
     HashAndTag.from_simple("tag-hash").should == HashAndTag.new("hash", tag = "tag")
    end

    it "self.from_simple with hash" do 
     HashAndTag.from_simple("hash").should == HashAndTag.new("hash")
    end
  end
end