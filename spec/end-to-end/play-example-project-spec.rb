require_relative './base-mk-deploy'
require 'restclient'

describe CsBuilder do

  include Helpers::EndToEnd

  APP = "play-221"

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
      config_dir: @prep[:config_dir], 
      git_dir: @prep[:project_dir],
      cmd: "play universal:packageZipTarball", 
      artifact: "target/universal/#{APP}-(.*).tgz",
      heroku_app: heroku_app,
      platform: "jdk-1.7",
      org: "test-org", 
      repo: "test-repo")
    
    url = "http://#{heroku_app}.herokuapp.com"
    RestClient.get(url).should eql("I'm a simple play app")
  end

end


