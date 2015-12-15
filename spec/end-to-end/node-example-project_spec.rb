require_relative './end-to-end-helper'
require 'cs-builder/cmds/artifacts/mk-from-git'
require 'cs-builder/cmds/artifacts/deploy-from-repo-commands'
require 'restclient'

include CsBuilder::Commands::Artifacts

describe CsBuilder do

  include Helpers::EndToEnd

  APP = "node-4.2.3"

  it "build and deploy a node app", :node => true do


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
      :cmd => "npm pack",
      :artifact => "#{APP}-(.*).tgz"
    })

    deploy_opts = shared.merge({
      :procfile => "package/Procfile",
      :heroku_app => heroku_app,
      :platform => "node-4.2.3"
    })
    
    mk = MkFromGit.new(@prep[:config_dir])     
    mk.run(mk_opts)

    deploy = DeployFromBranch.new(@prep[:config_dir])
    deploy.run(deploy_opts)

    sleep 4
    url = "http://#{heroku_app}.herokuapp.com"
    RestClient.get(url).should eql("Hello World\n")
  end

end
