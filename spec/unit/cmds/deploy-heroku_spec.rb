require 'cs-builder/heroku/heroku-deployer'
require 'cs-builder/heroku/slug-helper'
require 'dotenv'

include CsBuilder::Heroku
include CsBuilder::Heroku::SlugHelper
include CsBuilder::Io::SafeFileRemoval

Dotenv.load

describe "HerokuDeploySlug and Stack migrate" do

  heroku_app = ENV["TEST_HEROKU_APP"]
  heroku_stack = ENV["TEST_HEROKU_STACK"]
  result = ""
  slug = ""
  project = "build-1"
  cleanup = false
  puts "---Heroku APP: #{heroku_app}"
  puts "---Heroku STACK to set: #{heroku_stack}"

  def deploy_slug(slug, project, heroku_app, heroku_stack)
    deployer = HerokuDeployer.new
    deployer.deploy(slug, SlugHelper.processes_from_slug(slug), heroku_app, project, heroku_stack)
  end

  def compare_stacks?(app, stack)
    current_heroku_stack = `heroku stack -a #{app} | grep "*" | sed 's/* //' | sed 's/cedar-10/cedar/' | tr -d '\n' `
    stack == current_heroku_stack
  end

  def cleans_up(slug_path)
    safely_remove(slug_path)
  end

  it "uses different stack from the existing one (set in .env)" do
    expect(compare_stacks?(heroku_app, heroku_stack)).to be_falsey
  end

  it  "checks slug" do
    slug_path = "spec/tmp/node-0.10.20/slugs/org/node-0.10.20/master/"
    slug_file = "#{project}.tgz"
    slug = File.join(slug_path, slug_file)
    expect File.exists? slug
  end

  it "uploads heroku slug (and changes stack if needed)" do
    deploy_slug(slug, project, heroku_app, heroku_stack)
  end

  it "stack changed after deployment" do
    expect(compare_stacks?(heroku_app, heroku_stack)).to be_truthy
  end

  it "cleans up slug folder" do
    case cleanup
    when true
      cleans_up(slug_path)
      expect(Dir.entries(slug_path).size <= 2).to be_truthy
    else
      expect(Dir.entries(slug_path).size <= 2).to be_falsey
    end
  end

 

end
