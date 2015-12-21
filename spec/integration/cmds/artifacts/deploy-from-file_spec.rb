require 'cs-builder/cmds/artifacts/deploy-from-file'
require_relative './deploy-helper'

include CsBuilder::Commands::Artifacts 

describe CsBuilder::Commands::Artifacts::DeployFromFile do 

  include Helpers::Deploy

  def get_built_artifact
    current = Dir.pwd
    Dir.chdir(@result[:project_dir])
    out = `npm pack`
    puts "#{out}"
    puts "#{@result[:project_dir]}"
    puts "#{Dir.entries(@result[:project_dir])}"
    entries = Dir["#{@result[:project_dir]}/**/*.tgz"]
    puts "entries: #{entries}"
    out = entries[0]
    Dir.chdir(current)
    out
  end

  context "run" do 

    it "should do nothing if the artifact hasn't been built" do 
      init_example("node-4.2.3", extra_cmds: "git tag v0.0.1")
      cmd = DeployFromFile.new(@result[:config_dir], "some/file.tgz", tag: "v0.0.1")
      result = cmd.run(@deploy_opts)
      result[:deployed].should eql(false)
    end
    
    it "should deploy if the artifact has been built" do 
      init_example("node-4.2.3", extra_cmds: "git tag v0.0.1")
      path = get_built_artifact 
      cmd = DeployFromFile.new(@result[:config_dir], path, tag: "v0.0.1")
      result = cmd.run(@deploy_opts)
      result[:deployed].should eql(true)
    end
  end
end

