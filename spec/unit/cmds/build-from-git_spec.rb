require 'cs-builder/cmds/build-from-git'
require 'cs-builder/models/paths'
require 'cs-builder/in-out/utils'
require 'cs-builder/shell/runner'

require 'tmpdir'

include CsBuilder::Commands
include CsBuilder::Models
include CsBuilder::InOut
include CsBuilder::ShellRunner

describe BuildFromGit do 

  describe "run" do

    before(:each) do

      allow(Paths).to receive(:new).and_call_original

      @mock_repo = double
      allow(@mock_repo).to receive(:clone_and_update)

      allow(Repo).to receive(:new).and_return @mock_repo

      @dir = Dir.mktmpdir
      @cmd = BuildFromGit.new(@dir)

      allow(@cmd).to receive(:in_dir)
    end
    
    it "inits Paths correctly" do 
      @cmd.run(git_url: "git@github.com:org/repo.git", branch: "master", cmd: "blah")
      Paths.should have_received(:new).with(@dir, "org", "repo", "master")
    end
  end
end