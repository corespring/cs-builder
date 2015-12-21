require 'cs-builder/artifacts/repo-artifact-builder'
require 'cs-builder/artifacts/store/local-store'
require 'cs-builder/git/repo'
require 'cs-builder/init'
require_relative '../helpers/integration'
require 'tmpdir'

include CsBuilder
include CsBuilder::Artifacts
include Helpers::Integration
include CsBuilder::Git

describe CsBuilder::Artifacts::RepoArtifactBuilder do

  context "LocalStore" do
    before(:all) do
      @log = get_logger("repo-artifact-builder-spec")

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
      Init.init_cs_builder_dir(@root)
      repo_path = File.join(@root, "repos", "org", "repo", "branch")
      copy_example_project(NODE, repo_path)
      run_shell_cmds(repo_path, cmds)
    end

    def artifacts_path(root)
      File.join(root, "artifacts")
    end

    def new_local_store(root)
      LocalStore.new(artifacts_path(root))
    end

    def new_repo(root)
      Repo.new(@root, "url", "org", "repo", "branch")
    end

    before(:each) do
      init_repo
      @repo = new_repo(@root)
      @store = new_local_store(@root)
      @ra = RepoArtifactBuilder.new(@root, @repo, @store)
    end

    describe "build" do

      before(:each) do
        @first_build = @ra.build("npm pack", PATTERN)
      end

      it "builds the artifact and returns the build info" do
        @first_build[:build_info].should include({
          :version => "0.0.1",
          :path => "#{@repo.path}/node-0.10.20-0.0.1.tgz"
          })
      end

      it "skips the build if the artifact is there and force = false" do
        move_result = @ra.move_to_store(@first_build[:build_info])
        build_result = @ra.build("npm pack", PATTERN)
        @log.info("move_result: #{move_result}")
        @log.info("build_result: #{build_result}")
        build_result[:build_info][:path].should eql(move_result[:path])
        build_result.should include({
          :forced => false,
          :skipped => true
          })
      end

      it "re-builds if the artifact is there and force = true" do
        stored_path = @ra.move_to_store(@first_build[:build_info])
        build_two = @ra.build("npm pack", PATTERN, force:true)
        build_two.should include({
          :build_info => @first_build[:build_info],
          :skipped => false,
          :forced => true
          })
      end
    end

    # describe "artifact" do

    #   it "returns nil for an unbuilt artifact" do
    #     @ra.artifact(@repo.hash_and_tag).should be_nil
    #   end

    #   it "returns the artifact" do
    #     build_result = @ra.build_and_move_to_store("npm pack", PATTERN)
    #     @ra.artifact(@repo.hash_and_tag).should include({
    #       :virtual_path => "org/repo/0.0.1/#{@repo.hash_and_tag.to_simple}.tgz",
    #       :version => "0.0.1",
    #       :hash_and_tag => @repo.hash_and_tag
    #       })
    #   end

    # end

    # describe "artifact with tag", :tag => true do

    #   before(:each) do
    #     init_repo(DefaultCmds + "\ngit tag v0.0.1")
    #     @repo = new_repo(@root)
    #     @store = new_local_store(@root)
    #     @ra = RepoArtifactBuilder.new(@root, @repo, @store)
    #   end

    #   it "shouldn't have an artifact" do
    #     @ra.artifact(@repo.hash_and_tag).should be_nil
    #   end

    #   it "should have a git tag" do
    #     @repo.hash_and_tag.tag.should eql("v0.0.1")
    #   end

    #   it "returns the artifact" do
    #     build_result = @ra.build_and_move_to_store("npm pack", PATTERN)
    #     @ra.artifact(@repo.hash_and_tag).should include({
    #       :version => "0.0.1",
    #       :hash_and_tag => HashAndTag.new(@repo.hash_and_tag.hash, "v0.0.1"),
    #       :virtual_path => "org/repo/0.0.1/#{@repo.hash_and_tag.to_simple}.tgz"
    #     })
    #   end
    # end

end
end
