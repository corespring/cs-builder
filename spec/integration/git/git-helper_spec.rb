require 'cs-builder/git/git-helper'
require_relative '../helpers/integration'


include CsBuilder::Git 

describe CsBuilder::Git::GitHelper do 

  include Helpers::Integration 


  Cmds = <<-EOF
  git init
  git add .
  git commit . -m "first commit"
  EOF

  before(:each) do 
    @project = copy_project_to_tmp("node-4.2.3")
    run_shell_cmds(@project, Cmds)
  end

  describe "commit_hash" do 

    before(:each) do 
      Dir.chdir(@project)
      @expected = `git rev-parse --short HEAD`.chomp
      @hash = GitHelper.commit_hash(@project)
    end

    it "should not be an empty hash" do 
      @hash.empty?.should be(false)
    end

    it "should return the commit hash" do 
      @hash.should eql(@expected)
    end 
  end

  describe "commit_tag" do 

    before(:each) do 
      Dir.chdir(@project)
      @expected = "v0.0.1"
      run_shell_cmds(@project, "git tag #{@expected}")
      @tag = GitHelper.commit_tag(@project)
    end

    it "should not be an empty tag" do 
      @tag.empty?.should be(false)
    end

    it "should return the tag" do 
      @tag.should eql(@expected)
    end 
  end


  describe "has_tag?" do 

    before(:each) do 
      Dir.chdir(@project)
      @tag = "v0.0.1"
      run_shell_cmds(@project, "git tag #{@tag}")
    end

    it "should return true for a tag" do 
      GitHelper.has_tag?(@project, @tag).should be(true)
    end 
    
    it "should return false for unknown tag" do 
      GitHelper.has_tag?(@project, "v0.0.3").should be(false)
    end 
  end
end