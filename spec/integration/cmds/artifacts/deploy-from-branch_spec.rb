require 'cs-builder/cmds/artifacts/deploy-from-branch'
require_relative './deploy-helper'

include CsBuilder::Commands::Artifacts

describe CsBuilder::Commands::Artifacts::DeployFromBranch do

  include Helpers::Deploy

  def deploy_cmd
    DeployFromBranch.build(
      @result[:config_dir],
      @store,
      git_url: @result[:project_dir],
      branch: "master",
      org: "org",
      repo_name: "test-repo")
  end

  context "run" do

    it "should do nothing if the artifact hasn't been built" do
      init_example("node-4.2.3")
      result = deploy_cmd.run(@deploy_opts) 
      result[:deployed].should eql(false)
    end

    it "should deploy if the artifact has been built" do
      init_example("node-4.2.3")
      build_artifact
      result = deploy_cmd.run(@deploy_opts)
      result[:deployed].should eql(true)
    end
    
    
    it "should deploy if the artifact hash has changed an force is false" do
      init_example("node-4.2.3")
      build_artifact

      result = deploy_cmd.run(@deploy_opts)
      result[:deployed].should eql(true)

      cmds = <<-EOF
      touch new-file.txt
      git add new-file.txt
      git commit . -m "new file.txt"
      EOF

      run_shell_cmds(@result[:project_dir], cmds)
      
      build_artifact

      result = deploy_cmd.run(@deploy_opts.merge({:force => false}))
      result[:deployed].should eql(true)
    end

  end
end
