require 'cs-builder/cli'

module Helpers
  module EndToEnd
    def self.build_and_deploy_app( 
      app:,
      config_dir:,
      git_dir:,
      cmd:,
      artifact:,
      heroku_app:,
      platform:,
      procfile: "Procfile"
      )

    common = [
       "--config-dir=#{config_dir}",
       "--git=#{git_dir}",
       "--org=test-org",
       "--repo=repo",
       "--branch=master"]

    mk_args =  ["artifact-mk-from-git"] + 
      common + 
      ["--cmd=#{cmd}", "--artifact=#{artifact}"] 

   CsBuilder::CLI.start(mk_args)

    deploy_args = ["artifact-deploy-from-branch"] + common + 
      [ 
        "--procfile=#{procfile}",
        "--heroku-app=#{heroku_app}",
        "--platform=#{platform}" ]

    CsBuilder::CLI.start(deploy_args)

    sleep 10 

    end
  end
end