require 'cs-builder/procfile-reader'

include CsBuilder

describe ProcfileReader do
  it "should get repo" do 
    ProcfileReader.processes("spec/mock/procfile-one").should eql("speed-slug")
  end
end
