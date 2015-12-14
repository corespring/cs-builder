require_relative '../../helpers/integration'
require 'cs-builder/cmds/artifacts/list'
require 'cs-builder/cmds/artifacts/mk-from-git'
require 'cs-builder/log/logger'

include CsBuilder::Commands::Artifacts

describe CsBuilder::Commands::Artifacts::List do

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
      init_example("node-4.2.3", "npm pack", "an-example-cs-builder-app-(.*)\.tgz") 
    end 

    it "return an empty list",
      :node => true do
      run_shell_cmds(@result[:project_dir], @cmds)
      list = List.new(@result[:config_dir]).run(@opts)
      list.should eql([])
    end

    it "should return 1 tgz" do 
      run_shell_cmds(@result[:project_dir], @cmds)
      mk_result = MkFromGit.new(@result[:config_dir]).run(@opts)
      list = List.new(@result[:config_dir]).run(@opts)
      list.length.should eql(1)
      list[0].should include(File.join(@result[:config_dir], "artifacts", "org", "test-repo", "0.0.1"))
    end

  end 

end