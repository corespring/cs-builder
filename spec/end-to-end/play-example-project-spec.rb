require_relative './end-to-end-helper'
require_relative './end-to-end-helper'
require 'cs-builder/cmds/artifacts/mk-from-git'
require 'cs-builder/cmds/artifacts/deploy-from-repo-commands'
require 'restclient'

include CsBuilder::Commands::Artifacts

describe CsBuilder do

  include Helpers::EndToEnd

  APP = "play-221"

  it "should build and deploy a play app" do

    heroku_app = ENV["TEST_HEROKU_APP"]

    @prep = prepare_tmp_project(APP)

    cmds = <<-EOF
    git init
    git add .
    git commit . -m "commit"
    EOF

    shell_runs(@prep[:project_dir], cmds)
    
    shared = {
      :git => @prep[:project_dir],
      :org => "test-org",
      :repo => "test-repo",
      :branch => "master"
    }

    mk_opts = shared.merge({
      :cmd => "play universal:packageZipTarball",
      :artifact => "target/universal/#{APP}-(.*).tgz"
    })

    deploy_opts = shared.merge({
      :heroku_app => heroku_app,
      :platform => "jdk-1.7"
    })
    
    mk = MkFromGit.new(@prep[:config_dir])     
    mk.run(mk_opts)

    deploy = DeployFromBranch.new(@prep[:config_dir])
    deploy.run(deploy_opts)

    sleep 4
    url = "http://#{heroku_app}.herokuapp.com"
    RestClient.get(url).should eql("I'm a simple play app")
  end

end
