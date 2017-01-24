require_relative '../helpers/integration'
require 'cs-builder/cmds/build-from-git'

include CsBuilder::Commands

describe CsBuilder::Commands::BuildFromGit do

  include Helpers::Integration

  def init_example(example_project, cmd)
    @result = prepare_tmp_project(example_project)
    
    puts ">> #{@result}"

    @opts = {
      :git_url => @result[:project_dir],
      :branch => "master",
      :org => "org",
      :repo_name => "test-repo",
      :cmd => cmd
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
      init_example("node-4.2.3", "touch test.txt")  
      
      cmds = <<-EOF
        git init
        git add .
        git commit . -m "first commit"
      EOF

      run_shell_cmds(@result[:project_dir], cmds)
    end 

    it "build and move the node app artifact to artifacts/org/repo/version/tag.tgz",
      :node => true do

      cmd = BuildFromGit.new(@result[:config_dir])
      cmd.run(@opts)

      File.exist?("#{@result[:config_dir]}/repos/org/test-repo/master/test.txt").should eql(true)
    end

  end 

end