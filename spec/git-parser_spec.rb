require 'cs-builder/git-parser'

include CsBuilder

describe GitParser do
  it "should get repo" do 
    GitParser.repo("git@bitbucket.org:edeustace/speed-slug.git").should eql("speed-slug")
    GitParser.repo("git@github.com:org/repo.git").should eql("repo")
  end
  it "should get org" do 
    GitParser.org("git@bitbucket.org:edeustace/speed-slug.git").should eql("edeustace")
    GitParser.org("git@github.com:org/repo.git").should eql("org")
  end
end
