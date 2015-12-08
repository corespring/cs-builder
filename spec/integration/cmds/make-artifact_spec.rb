require_relative '../helpers'
require 'cs-builder/cmds/make-artifact'

describe CsBuilder::Commands::MakeArtifactGit do

  include Helpers::Integration
    
  context "with a node app" do 

    before(:each) do 
      @result = prepare_tmp_project("node-4.2.3")
      @opts = {
        :git => @result[:project_dir],
        :org => "org",
        :repo => "test-repo",
        :branch => "master",
        :cmd => "npm pack",
        :artifact => "an-example-cs-builder-app-(.*)\.tgz"
      }
      
      @cmds = <<-EOF
        git init
        git add .
        git commit . -m "first commit"
      EOF
    end 

    it "build and move the node app artifact to artifacts/org/repo/version/tag.tgz",
      :node => true do

      @cmds << <<-EOF
      git tag v0.0.1
      EOF

      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      mk_result[:path].should eql(File.join(@result[:config_dir], "artifacts/org/test-repo/0.0.1/v0.0.1.tgz"))
    end
    
    it "build and move the node app artifact to artifacts/org/repo/version/sha.tgz", 
      :node => true do
      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      File.dirname(mk_result[:path]).should eql(File.join(@result[:config_dir], "artifacts/org/test-repo/0.0.1"))
    end

    it "skips the build if the artifact is already there", 
      :skip => true, 
      :node => true do 
      run_shell_cmds(@result[:project_dir], @cmds)
      MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      mk_result = MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      mk_result[:skipped].should eql(true)
    end
    
    it "doesn't skip the build if the artifact is already there and force = true", 
      :force => true, 
      :node => true do 
      run_shell_cmds(@result[:project_dir], @cmds)
      MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      @opts[:force] = true
      mk_result = MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      mk_result[:forced].should eql(true)
    end

  end 

  context "with a play app" do 

    before(:each) do 
      @result = prepare_tmp_project("play-221")

      @cmds = <<-EOF
        git init
        git add .
        git commit . -m "first commit"
        EOF

      @opts = {
        :git => @result[:project_dir],
        :org => "org",
        :repo => "test-repo",
        :branch => "master",
        :cmd => "java -version && play clean dist",
        :artifact_format => "zip",
        :artifact => "target/universal/play-221-(.*).zip"
      }
    end
    
    it "builds and move the play app artifact", :play => true do
      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      File.dirname(mk_result[:path]).should eql(File.join(@result[:config_dir], "artifacts/org/test-repo/1.0-SNAPSHOT"))
    end
    
    it "builds and move the play app artifact", :play => true do

      @cmds << <<-EOF
      git tag v1.0.0
      EOF
      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MakeArtifactGit.new("DEBUG", @result[:config_dir]).run(@opts)
      mk_result[:path].should eql(File.join(@result[:config_dir], "artifacts/org/test-repo/1.0-SNAPSHOT/v1.0.0.zip"))
    end
  end

end