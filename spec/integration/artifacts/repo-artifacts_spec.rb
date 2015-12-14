require 'cs-builder/artifacts/repo-artifacts'
require 'cs-builder/git/repo'
require 'cs-builder/init'
require_relative '../helpers/integration'

include CsBuilder
include CsBuilder::Artifacts
include Helpers::Integration
include CsBuilder::Git

describe CsBuilder::Artifacts::RepoArtifacts do 


  before(:all) do 
    @log = get_logger("repo-artifacts-spec")

    # clean up tmp
    Dir["#{Dir.tmpdir}/repo_artifacts*"].each{ |p|
      FileUtils.rm_rf(p)
    }
  end

  DefaultCmds = <<-EOF
  ls -la
  git init
  git add .
  git commit . -m "first commit"
  EOF
  
  NODE = "node-0.10.20"
  
  PATTERN = "#{NODE}-(.*).tgz"

  def init_repo(cmds = DefaultCmds)
    @root = Dir.mktmpdir("repo_artifacts")
    @log.debug("@root: #{@root}")
    @paths = Paths.new(@root, "org", "repo", "branch")
    Init.init_cs_builder_dir(@root)
    copy_example_project(NODE, @paths.repo)
    run_shell_cmds(@paths.repo, cmds)
  end

  describe "build" do 

    before(:each) do 
      init_repo
      @repo = Repo.new(@root, "url", "org", "repo", "branch")
      @re = RepoArtifacts.new(@root, @repo)
      @first_build = @re.build("npm pack", PATTERN)
    end
    
    it "builds the artifact and returns the build info" do 
      @first_build[:build_info].should include({
        :version => "0.0.1", 
        :extname => ".tgz", 
        :path => "#{@repo.path}/node-0.10.20-0.0.1.tgz"
        })
    end
    
    it "skips the build if the artifact is there and force = false" do 
      stored_path = @re.move_to_store(@first_build[:build_info])
      result = @re.build("npm pack", PATTERN)

      result[:existing_artifact][:path].should eql(stored_path)
      result.should include({
        :forced => false,
        :skipped => true
        })
    end
    
    it "re-builds if the artifact is there and force = true" do 
      stored_path = @re.move_to_store(@first_build[:build_info])
      build_two = @re.build("npm pack", PATTERN, force:true)
      build_two.should include({
        :build_info => @first_build[:build_info],
        :skipped => false,
        :forced => true
        })
    end
  end

  describe "artifact" do 

    before(:each) do 
      init_repo
      @repo = Repo.new(@root, "url", "org", "repo", "branch")
      @re = RepoArtifacts.new(@root, @repo)
      @re.artifact(@repo.hash_and_tag).should be_nil 
    end

    it "returns nil for an unbuilt artifact" do
      @re.artifact(@repo.hash_and_tag).should be_nil 
    end
    
    it "returns the artifact" do
      build_result = @re.build_and_move_to_store("npm pack", PATTERN)
      @re.artifact(@repo.hash_and_tag).should include({
        :path => "#{@paths.artifacts}/0.0.1/#{@repo.hash_and_tag.to_simple}.tgz",
        :version => "0.0.1",
        :hash => @repo.hash_and_tag.hash,
        :tag => @repo.hash_and_tag.tag
        }) 
    end

  end

  describe "artifact with tag", :tag => true do 
    
    before(:each) do 
      init_repo(DefaultCmds + "\ngit tag v0.0.1")
      @repo = Repo.new(@root, "url", "org", "repo", "branch")
      @re = RepoArtifacts.new(@root, @repo)
    end
   
    it "shouldn't have an artifact" do 
      @re.artifact(@repo.hash_and_tag).should be_nil 
    end

    it "should have a git tag" do 
      @repo.hash_and_tag.tag.should eql("v0.0.1")
    end

    it "returns the artifact" do
      build_result = @re.build_and_move_to_store("npm pack", PATTERN)
      @re.artifact(@repo.hash_and_tag).should include({
        :version => "0.0.1",
        :tag => "v0.0.1",
        :hash => @repo.hash_and_tag.hash,
        :path => "#{@paths.artifacts}/0.0.1/#{@repo.hash_and_tag.to_simple}.tgz"
      }) 
    end

  end

  describe "artifact_from_tag", :tag => true do 
    before(:each) do 
      init_repo(DefaultCmds + "\ngit tag v0.0.1")
      @repo = Repo.new(@root, "url", "org", "repo", "branch")
      @re = RepoArtifacts.new(@root, @repo)
      build_result = @re.build_and_move_to_store("npm pack", PATTERN)
    end
   
    it "shouldn't have an artifact" do 
      @re.artifact_from_tag(@repo.hash_and_tag.tag).should eql("#{@paths.artifacts}/0.0.1/#{@repo.hash_and_tag.to_simple}.tgz") 
    end
  end
end