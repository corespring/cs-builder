
require_relative './helpers'

describe CsBuilder do

  include Helpers::Integration

  it "should create a binary and a slug using the commit hash" do

    cmds = <<-EOF
    git init
    git add .
    git commit . -m "first commit"
    git rev-parse --short HEAD
    EOF

    results = build_git("node-0.10.20", cmds, "node-0.10.20")
    puts "results: #{results}"

    commit_hash = results[:cmd_result].chomp.lines.last
    File.basename(results[:binary_result]).should eql("#{commit_hash}.tgz")
    File.basename(results[:slug_result]).should eql("#{commit_hash}.tgz")
  end

end