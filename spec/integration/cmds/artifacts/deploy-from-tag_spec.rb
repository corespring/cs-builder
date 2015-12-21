require 'cs-builder/cmds/artifacts/deploy-from-tag'
require_relative './deploy-helper'

include CsBuilder::Commands::Artifacts 

describe CsBuilder::Commands::Artifacts::DeployFromTag do 

  include Helpers::Deploy

  context "run" do 

    def cmd 
      DeployFromTag.build(
        @result[:config_dir],
        @store, 
        "v0.0.1",
        git_url: @result[:project_dir],
        org: "org",
        repo_name: "test-repo"
      )
    end
    
    it "should do nothing if the artifact hasn't been built" do 
      init_example("node-4.2.3", extra_cmds: "git tag v0.0.1")
      result = cmd.run(@deploy_opts)
      result[:deployed].should eql(false)
    end
    
    it "should deploy if the artifact has been built" do 
      init_example("node-4.2.3", extra_cmds: "git tag v0.0.1")
      build_artifact
      result = cmd.run(@deploy_opts)
      result[:deployed].should eql(true)
    end
  end
end

