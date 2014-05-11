require 'cs-builder/git/git-parser'

include CsBuilder

describe GitUrlParser do
  it "should get repo" do
    GitUrlParser.repo("git@bitbucket.org:edeustace/speed-slug.git").should eql("speed-slug")
    GitUrlParser.repo("git@github.com:org/repo.git").should eql("repo")
  end
  it "should get org" do
    GitUrlParser.org("git@bitbucket.org:edeustace/speed-slug.git").should eql("edeustace")
    GitUrlParser.org("git@github.com:org/repo.git").should eql("org")
  end
end
