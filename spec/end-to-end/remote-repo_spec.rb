require_relative './base-mk-deploy'

describe CsBuilder do 

  describe "pull mk deploy" do 

    it "pulls the repo, mks and deploys" do 


      config_dir = "spec/tmp/remote-repo"
      FileUtils.mkdir_p(config_dir)

      repo = ENV["TEST_REMOTE_REPO"]
      heroku_app = ENV["TEST_HEROKU_APP"]

      Helpers::EndToEnd.build_and_deploy_app(
        config_dir: config_dir, 
        git_dir: repo,
        cmd: "npm pack",
        artifact: "node-4.2.3-(.*).tgz",
        heroku_app: heroku_app,
        procfile: "package/Procfile",
        platform: "node-4.2.3"
      ) 

    end

  end

end