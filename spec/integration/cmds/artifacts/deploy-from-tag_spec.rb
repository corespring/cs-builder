require 'cs-builder/cmds/artifacts/deploy-from-repo-commands'
require 'cs-builder/cmds/artifacts/mk-from-git'
require_relative '../../helpers/integration'

include CsBuilder::Commands::Artifacts 

describe CsBuilder::Commands::Artifacts::DeployFromTag do 

  include Helpers::Integration

  def init_example(example_project)

    heroku_app = ENV["TEST_HEROKU_APP"]
    @log = CsBuilder::Log.get_logger("deploy-from-tag-spec")
    @log.debug("heroku_app: #{heroku_app}")

    @result = prepare_tmp_project(example_project)
    @opts = {
      :git => @result[:project_dir],
      :org => "org",
      :repo => "test-repo",
      :branch => "master",
      :platform => "node-4.2.3",
      :heroku_app => heroku_app, 
      :heroku_stack => "cedar-14",
      :procfile => "package/Procfile",
      :tag => "v0.0.1"
    }
    
    @cmds = <<-EOF
      git init
      git add .
      git commit . -m "first commit"
      git tag v0.0.1
    EOF

    run_shell_cmds(@result[:project_dir], @cmds)

    @paths = Paths.new(@result[:config_dir], "org", "test-repo", "branch")
  end

  def build_artifact
    mk = MkFromGit.new(@result[:config_dir])
    mk.run({
      :git => @result[:project_dir],
      :org => "org",
      :repo => "test-repo",
      :branch => "master",
      :cmd  => "npm pack",
      :artifact => "an-example-cs-builder-app-(.*).tgz"
    })
  end

  context "run" do 

    it "should do nothing if the artifact hasn't been built" do 
      init_example("node-4.2.3")
      cmd = DeployFromTag.new(@result[:config_dir])
      result = cmd.run(@opts)
      result[:deployed].should eql(false)
    end
    
    it "should deploy if the artifact has been built" do 
      init_example("node-4.2.3")
      build_artifact
      cmd = DeployFromTag.new(@result[:config_dir])
      result = cmd.run(@opts)
      result[:deployed].should eql(true)
    end
  end
end

