require_relative '../../helpers/integration'
require 'cs-builder/cmds/artifacts/mk-from-git'
require 'cs-builder/artifacts/store/local-store'
require 'cs-builder/log/logger'

include CsBuilder::Commands::Artifacts
include CsBuilder::Artifacts

describe CsBuilder::Commands::Artifacts::MkFromGit do

  include Helpers::Integration

  def init_example(example_project, cmd, artifact)
    @result = prepare_tmp_project(example_project)
    @store = LocalStore.new(File.join(@result[:config_dir], "artifacts"))
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

      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir], @store).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      mk_result[:store_info][:path].should eql(expected)
    end
    
    it "build and move the node app artifact to artifacts/org/repo/version/sha.tgz", 
      :node => true do
      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir], @store).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      File.dirname(mk_result[:store_info][:path]).should eql(File.dirname(expected))
    end

    it "skips the build if the artifact is already there", 
      :skipped => true, 
      :node => true do 
      run_shell_cmds(@result[:project_dir], @cmds)
      MkFromGit.new(@result[:config_dir], @store).run(@opts)
      mk_result = MkFromGit.new(@result[:config_dir], @store).run(@opts)
      mk_result[:skipped].should eql(true)
    end
    
    it "doesn't skip the build if the artifact is already there and force = true", 
      :force => true, 
      :node => true do 
      run_shell_cmds(@result[:project_dir], @cmds)
      MkFromGit.new(@result[:config_dir], @store).run(@opts)
      @opts[:force] = true
      mk_result = MkFromGit.new(@result[:config_dir], @store).run(@opts)
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
      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir], @store).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      File.dirname(mk_result[:store_info][:path]).should eql(File.dirname(expected))
    end
    
    it "builds and move the play app artifact", :play => true do

      @cmds << <<-EOF
      git tag v1.0.0
      EOF
      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir], @store).run(@opts)
      expected = Dir["#{@paths.artifacts}/**/*.tgz"][0]
      mk_result[:store_info][:path].should eql(expected)
    end
  end

end