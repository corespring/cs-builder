require_relative '../../helpers/integration'
require 'cs-builder/cmds/artifacts/mk-from-git'
require 'cs-builder/log/logger'

include CsBuilder::Commands::Artifacts

describe CsBuilder::Commands::Artifacts::MkFromGit do

  include Helpers::Integration


  def init_example(example_project, cmd, artifact)
    @result = prepare_tmp_project(example_project)
    @opts = {
      :git => @result[:project_dir],
      :org => "org",
      :repo => "test-repo",
      :branch => "master",
      :cmd => cmd,
      :artifact => artifact 
    }
    
    @cmds = <<-EOF
      git init
      git add .
      git commit . -m "first commit"
    EOF

    @paths = Paths.new(@result[:config_dir], "org", "test-repo", "branch")
  end
  
  context "with a node app" do 

    before(:each) do
      init_example("node-4.2.3", "npm pack", "node-4.2.3-(.*)\.tgz") 
    end 

    it "build and move the node app artifact to artifacts/org/repo/version/tag.tgz",
      :node => true do

      @cmds << <<-EOF
      git tag v0.0.1
      EOF

      shell_runs(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir]).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      mk_result[:stored_path].should eql(expected)
    end
    
    it "build and move the node app artifact to artifacts/org/repo/version/sha.tgz", 
      :node => true do
      shell_runs(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir]).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      File.dirname(mk_result[:stored_path]).should eql(File.dirname(expected))
    end

    it "skips the build if the artifact is already there", 
      :skip => true, 
      :node => true do 
      shell_runs(@result[:project_dir], @cmds)
      MkFromGit.new(@result[:config_dir]).run(@opts)
      mk_result = MkFromGit.new(@result[:config_dir]).run(@opts)
      mk_result[:skipped].should eql(true)
    end
    
    it "doesn't skip the build if the artifact is already there and force = true", 
      :force => true, 
      :node => true do 
      shell_runs(@result[:project_dir], @cmds)
      MkFromGit.new(@result[:config_dir]).run(@opts)
      @opts[:force] = true
      mk_result = MkFromGit.new(@result[:config_dir]).run(@opts)
      mk_result[:forced].should eql(true)
    end

  end 

  context "with a play app" do 

    before(:each) do 
      init_example("play-221", 
        "play clean universal:packageZipTarball",
        "target/universal/play-221-(.*).tgz")
    end
    
    it "builds and move the play app artifact", :play => true do
      shell_runs(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir]).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      File.dirname(mk_result[:stored_path]).should eql(File.dirname(expected))
    end
    
    it "builds and move the play app artifact", :play => true do

      @cmds << <<-EOF
      git tag v1.0.0
      EOF
      shell_runs(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir]).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      mk_result[:stored_path].should eql(expected)
    end
  end

end