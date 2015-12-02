
require_relative './helpers'

describe CsBuilder do

  include Helpers::Integration

  it "should create a binary and a slug using git tag if present" do

    cmds = <<-EOF
    git init
    git add .
    git commit . -m "first commit"
    git tag v0.0.1
    git status
    git tag --contains HEAD
    EOF

    results = build_git("node-0.10.20", cmds, "node-0.10.20")
    puts "results: #{results}"
    File.basename(results[:binary_result]).should eql("v0.0.1.tgz")
    File.basename(results[:slug_result]).should eql("v0.0.1.tgz")
  end

end