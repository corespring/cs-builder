require 'cs-builder/heroku-deployer'

include CsBuilder

describe HerokuDeployer do
  it "should deploy" do 

    deployer = HerokuDeployer.new

    #deployer.deploy(
    #  "spec/test-slugs/slug.tgz",
    #  { :web => "./target/universal/stage/bin/blahblah -Dhttp.port=${PORT}"},
    #  "new-slug-deploy-test"
    #)

  end
end
