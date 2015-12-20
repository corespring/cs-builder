require 'cs-builder/cmds/artifacts/deploy-from-repo-commands'
require 'cs-builder/cmds/artifacts/mk-from-git'
require_relative '../../helpers/integration'
require 'dotenv'

include CsBuilder::Commands::Artifacts

describe CsBuilder::Commands::Artifacts::DeployFromBranch do

  Dotenv.load

  include Helpers::Integration


  def init_example(example_project)

    heroku_app = ENV["TEST_HEROKU_APP"]
    puts ">>> #{heroku_app}"
    @log = CsBuilder::Log.get_logger("deploy-from-branch-spec")
    @log.debug("heroku_app: #{heroku_app}")

    @result = prepare_tmp_project(example_project)
    @store = RemoteAndLocalStore.build(File.join(@result[:config_dir], "artifacts"), bucket_name: "deploy-from-branch-spec")

    @opts = {
      :git => @result[:project_dir],
      :org => "org",
      :repo => "test-repo",
      :branch => "master",
      :platform => "node-4.2.3",
      :heroku_app => heroku_app,
      :heroku_stack => "cedar-14",
      :procfile => "package/Procfile"
    }

    @cmds = <<-EOF
      git init
      git add .
      git commit . -m "first commit"
    EOF

    run_shell_cmds(@result[:project_dir], @cmds)

    @paths = Paths.new(@result[:config_dir], "org", "test-repo", "branch")
  end

  def build_artifact
    mk = MkFromGit.new(@result[:config_dir], @store)
    mk.run({
      :git => @result[:project_dir],
      :org => "org",
      :repo => "test-repo",
      :branch => "master",
      :cmd  => "npm pack",
      :artifact => "node-4.2.3-(.*).tgz"
    })
  end

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
      result = deploy_cmd.run(@opts)
      result[:deployed].should eql(false)
    end

    it "should deploy if the artifact has been built" do
      init_example("node-4.2.3")
      build_artifact
      result = deploy_cmd.run(@opts)
      result[:deployed].should eql(true)
    end
  end
end
