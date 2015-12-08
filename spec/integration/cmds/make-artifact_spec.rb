require_relative '../helpers'
require 'cs-builder/cmds/make-artifact'

describe CsBuilder::Commands::MakeArtifactGit do

  include Helpers::Integration
  
  it "build and move the node app artifact to artifacts/org/repo/version/tag.tgz" do

    result = prepare_tmp_project("node-4.2.3")

    cmds = <<-EOF
    git init
    git add .
    git commit . -m "first commit"
    git tag v0.0.1
    EOF

    run_shell_cmds(result[:project_dir], cmds)
    
    opts = {
      :git => result[:project_dir],
      :org => "org",
      :repo => "test-repo",
      :branch => "master",
      :cmd => "npm pack",
      :artifact_format => "tgz",
      :artifact => "an-example-cs-builder-app-(.*)\.tgz"
    }

    artifact_path = MakeArtifactGit.new("DEBUG", result[:config_dir]).run(opts)
    artifact_path.should eql(File.join(result[:config_dir], "artifacts/org/test-repo/0.0.1/v0.0.1.tgz"))
  end
  
  it "build and move the node app artifact to artifacts/org/repo/version/sha.tgz" do

    result = prepare_tmp_project("node-4.2.3")

    cmds = <<-EOF
    git init
    git add .
    git commit . -m "first commit"
    EOF

    run_shell_cmds(result[:project_dir], cmds)
    
    opts = {
      :git => result[:project_dir],
      :org => "org",
      :repo => "test-repo",
      :branch => "master",
      :cmd => "npm pack",
      :artifact_format => "tgz",
      :artifact => "an-example-cs-builder-app-(.*)\.tgz"
    }

    artifact_path = MakeArtifactGit.new("DEBUG", result[:config_dir]).run(opts)
    File.dirname(artifact_path).should eql(File.join(result[:config_dir], "artifacts/org/test-repo/0.0.1"))
  end

  # it "build and move the play app artifact" do

  #   result = prepare_tmp_project("play-221")

  #   cmds = <<-EOF
  #   git init
  #   git add .
  #   git commit . -m "first commit"
  #   EOF

  #   run_shell_cmds(result[:project_dir], cmds)
    
  #   opts = {
  #     :git => result[:project_dir],
  #     :org => "org",
  #     :repo => "test-repo",
  #     :branch => "master",
  #     :cmd => "java -version && play clean dist",
  #     :artifact_format => "zip",
  #     :artifact => "target/universal/play-221-(.*).zip"
  #   }

  #   MakeArtifactGit.new("DEBUG", result[:config_dir]).run(opts)
  # end
end