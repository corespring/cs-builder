require 'cs-builder/cli'
require_relative '../integration/helpers/integration'


module Helpers
  module EndToEnd

    include Helpers::Integration

    def self.build_and_deploy_app( 
      config_dir:,
      git_dir:,
      cmd:,
      artifact:,
      heroku_app:,
      platform:,
      procfile: "Procfile",
      org: nil,
      repo: nil
      )

    common = [
       "--log-config=spec/log-config.yml",
       "--config-dir=#{config_dir}",
       "--git=#{git_dir}",
       org.nil? ? nil :  "--org=test-org" ,
       repo.nil? ? nil : "--repo=repo",
       "--branch=master"].compact


    mk_args =  ["artifact-mk-from-git"] + 
      common + 
      ["--cmd=#{cmd}", "--artifact=#{artifact}"] 

    puts "mk_args: #{mk_args}"
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