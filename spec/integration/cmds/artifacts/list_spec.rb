require_relative '../../helpers/integration'
require 'cs-builder/cmds/artifacts/list'
require 'cs-builder/cmds/artifacts/mk-from-git'
require 'cs-builder/log/logger'
require 'cs-builder/artifacts/store/remote-and-local-store'

include CsBuilder::Commands::Artifacts
include CsBuilder::Artifacts

describe CsBuilder::Commands::Artifacts::List do

  include Helpers::Integration

  def init_example(example_project, cmd, artifact)
    @result = prepare_tmp_project(example_project)
    @org = "org"
    @repo = "repo"
    @opts = {
      :git_url => @result[:project_dir],
      :org => @org, 
      :repo_name => @repo, 
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
      @store = RemoteAndLocalStore.build(File.join(@result[:config_dir], "artifacts"))
      config_dir = @result[:config_dir]
      @list = List.new(config_dir, @store)
    end 

    it "return an empty list",
      :node => true do
      run_shell_cmds(@result[:project_dir], @cmds)
      @list.run(org: @org, repo: @repo).should eql("")
    end

    it "should return 1 tgz" do 
      run_shell_cmds(@result[:project_dir], @cmds)
      config_dir = @result[:config_dir]
      mk_result = MkFromGit.new(config_dir, @store).run(@opts)
      puts "mk_result: #{mk_result}"
      out = @list.run(org: @org, repo: @repo)
      puts ">> list: #{out}"
      out.should include("#{@org}/#{@repo}/0.0.1")
    end

  end 

end