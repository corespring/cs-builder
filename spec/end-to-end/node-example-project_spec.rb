require_relative './end-to-end-helper'
require_relative './base-mk-deploy'
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

    run_shell_cmds(@prep[:project_dir], cmds)
    
    Helpers::EndToEnd.build_and_deploy_app(
      app: APP, 
      config_dir: @prep[:config_dir], 
      git_dir: @prep[:project_dir],
      cmd: "npm pack", 
      artifact: "#{APP}-(.*).tgz",
      heroku_app: heroku_app,
      procfile: "package/Procfile",
      platform: "node-4.2.3"
      )

    
    url = "http://#{heroku_app}.herokuapp.com"
    RestClient.get(url).should eql("Hello World\n")
  end

end
