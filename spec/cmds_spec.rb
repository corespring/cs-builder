require 'cs-builder/cmds'

include CsBuilder

describe Commands do
  it "should ping" do
    p = Commands::Ping.new
    p.run("hello world").should eql("hello world")
    p.run("hello world", :reverse => true).should eql("hello world".reverse)
  end
end
