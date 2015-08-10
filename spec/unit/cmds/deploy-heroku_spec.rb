require 'cs-builder/heroku/heroku-deployer'
require 'cs-builder/heroku/slug-helper'
require 'dotenv'

include CsBuilder::Heroku
include CsBuilder::Heroku::SlugHelper

Dotenv.load

describe "HerokuDeploySlug and Stack migrate" do

  heroku_app = ENV["TEST_HEROKU_APP"]
  heroku_stack = ENV["TEST_HEROKU_STACK"]
  result = ""
  slug = ""
  project = "build-1"
  puts "---Heroku APP: #{heroku_app}"
  puts "---Heroku STACK to set: #{heroku_stack}"

  def deploy_slug(slug, project, heroku_app, heroku_stack)
    deployer = HerokuDeployer.new
    deployer.deploy(slug, SlugHelper.processes_from_slug(slug), heroku_app, project, heroku_stack)
  end

  def compare_stacks?(app, stack)
    current_heroku_stack = `heroku stack -a #{app} | grep "*" | sed 's/* //' | sed 's/cedar-10/cedar/' | tr -d '\n' `

    if stack == current_heroku_stack
      true
    else 
      false
    end

  end

  it "uses different stack from the existing one (set in .env)" do
    expect(compare_stacks?(heroku_app, heroku_stack)).to be_falsey
  end

  it  "checks slug" do
    #slug_path = "spec/tmp/make-slug/slugs/org/repo/branch/"
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

end
