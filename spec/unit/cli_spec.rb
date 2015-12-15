require 'cs-builder/cli'
describe CLI do 

  def mk_stub(n)
    d = double 
    stub_const(n, d)
    d.stub(:new).with(String){ |s| d } 
    d.stub(:run).with(anything()){|opts| opts}
  end

  describe "mk-artifact-from-git" do 

    it "should" do 
      mk_stub("CsBuilder::Commands::Artifacts::MkFromGit")
      CsBuilder::CLI.start(%w[artifact-mk-from-git --cmd="build" --branch=b --artifact-pattern="p" --git=git@github.com:blah/blah.git])
    end
  end
end