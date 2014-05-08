require 'cs-builder/cmds/build'

include CsBuilder::Commands

describe BuildFromFile do 
  it "should build" do 

    config_dir = "spec/mock/build-from-file"
    FileUtils.rm_rf(config_dir)
    FileUtils.mkdir_p(config_dir)
    cmd = BuildFromFile.new("DEBUG", File.expand_path(config_dir))
    uid = "build-1"
    out = cmd.run({
      :org => "org",
      :repo => "repo",
      :branch => "branch",
      :external_src => File.expand_path("spec/mock/mock-project-1"),
      :cmd => "echo \"hello\" >> asset.txt",
      :build_assets => ["asset.txt", "existing.txt"],
      :uid => uid
     })

    out.should eql(File.expand_path("#{config_dir}/binaries/org/repo/branch/build-1.tgz"))
    
    extracted = File.dirname(out) 
    `tar xvf #{out} -C #{extracted}` 

    IO.read(File.join(extracted, "asset.txt")).should eql "hello\n"
    IO.read(File.join(extracted, "existing.txt")).should eql "I'm an existing asset"

    FileUtils.rm_rf("spec/mock/build-from-file")
  end

end 

