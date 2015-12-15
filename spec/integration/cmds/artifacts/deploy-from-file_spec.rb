require 'cs-builder/cmds/artifacts/deploy-from-file'
require_relative '../../helpers/integration'

include CsBuilder::Commands::Artifacts 

describe CsBuilder::Commands::Artifacts::DeployFromFile do 

  include Helpers::Integration

  def init_example(example_project)

    heroku_app = ENV["TEST_HEROKU_APP"]
    @log = CsBuilder::Log.get_logger("deploy-from-file-spec")
    @log.debug("heroku_app: #{heroku_app}")

    @result = prepare_tmp_project(example_project)
    @opts = {
      :platform => "node-4.2.3",
      :heroku_app => heroku_app, 
      :heroku_stack => "cedar-14",
      :procfile => "package/Procfile",
      :tag => "v0.0.1",
      :hash => "some-made-up-hash"
    }
    
    @cmds = <<-EOF
      git init
      git add .
      git commit . -m "first commit"
      git tag v0.0.1
    EOF

    shell_runs(@result[:project_dir], @cmds)

    @paths = Paths.new(@result[:config_dir], "org", "test-repo", "branch")
  end

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
      init_example("node-4.2.3")
      cmd = DeployFromFile.new(@result[:config_dir])
      @opts[:artifact_file] = "/some/path.tgz" 
      result = cmd.run(@opts)
      result[:deployed].should eql(false)
    end
    
    it "should deploy if the artifact has been built" do 
      init_example("node-4.2.3")
      cmd = DeployFromFile.new(@result[:config_dir])
      @opts[:artifact_file] = get_built_artifact 
      @opts[:force] = true
      result = cmd.run(@opts)
      result[:deployed].should eql(true)
    end
  end
end

