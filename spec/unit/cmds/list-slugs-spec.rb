require 'cs-builder/cmds/list-slugs'

include CsBuilder::Commands

describe ListSlugs do 
  it "should list" do 
    cmd = ListSlugs.new("DEBUG", File.expand_path("spec/mock/list-slugs"))
    out = cmd.run({})
    out.should eql("...coming...")
  end

end 