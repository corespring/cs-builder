require 'cs-builder/cmds/build'

include CsBuilder::Commands

describe BuildFromFile do

  def run_build(path, build_assets: [])
    config_dir = path
    FileUtils.rm_rf(config_dir)
    FileUtils.mkdir_p(config_dir)
    cmd = BuildFromFile.new(File.expand_path(config_dir))
    uid = "build-1"
    out = cmd.run({
      :org => "org",
      :repo => "repo",
      :branch => "branch",
      :external_src => File.expand_path("spec/mock/mock-project-1"),
      :cmd => "echo \"hello\" >> asset.txt",
      :build_assets => build_assets,
      :uid => uid
     })
     yield out
    FileUtils.rm_rf(config_dir)
  end

  it "should create an archive if build_assets are defined" do
    config_dir = "spec/tmp/build-from-file"
    run_build(config_dir, build_assets: ["asset.txt", "existing.txt"]){ |out|
      out.should eql(File.expand_path("#{config_dir}/binaries/org/repo/branch/build-1.tgz"))
      extracted = File.dirname(out)
      `tar xvf #{out} -C #{extracted}`
      IO.read(File.join(extracted, "asset.txt")).should eql "hello\n"
      IO.read(File.join(extracted, "existing.txt")).should eql "I'm an existing asset"
    }
  end

  it "should only run the command if there are no build assets" do
    path = "spec/tmp/build-from-file-two"
    run_build(path){ |out|
      out.should eql("")
      File.directory?( File.join( path, "binaries", "org" ) ).should be(false)
      File.exists?(File.join(path, "repos", "org", "branch", "build-1", "assets.txt"))
    }
  end

end
