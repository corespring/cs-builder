require 'cs-builder/cli'
describe CLI do 

  def mk_stub(n)
    d = double 
    stub_const(n, d)
    d.stub(:new).with(anything(), anything()){ |s| d } 
    d.stub(:run).with(anything()){|opts| 
      opts
    }
    d
  end
  

  describe "artifact-list" do 
    it "call :run" do 
      double = mk_stub("CsBuilder::Commands::Artifacts::List")
      out = CsBuilder::CLI.start(%w[artifact-list --org=org --repo=repo])
      double.should have_received(:run).with(
        {
          :org => "org", 
          :repo => "repo"
        })
    end
  end

  describe "mk-artifact-from-git" do 

    it "call :run" do 
      double = mk_stub("CsBuilder::Commands::Artifacts::MkFromGit")
      args = %w[artifact-mk-from-git --cmd=cmd --branch=branch --artifact=artifact --git=git]
      lambda { CsBuilder::CLI.start(args) }.should_not raise_error
      double.should have_received(:run).with(
        {
          :git_url => "git", 
          :branch => "branch",
          :cmd => "cmd",
          :artifact => "artifact",
          :org => nil,
          :repo_name => nil,
          :force => false
        })
    end
  end

end