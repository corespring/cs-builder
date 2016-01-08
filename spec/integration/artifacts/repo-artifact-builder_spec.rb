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


      describe "build with hash and tag updated by build cmd" do 

        it "picks up the new hash and tag created by the build cmd" do 

          tweak = <<-EOF
#!/usr/bin/env bash
touch new-file.txt
git add . 
git commit . -m "add new file.txt"
git tag v0.0.2
npm pack
          EOF

          path = "#{@repo.path}/tweak.sh"
          File.open(path,  'w') { |file| 
            file.write(tweak) 
          }

          FileUtils.chmod(0755, path)
          
          initial_hash_and_tag = @repo.hash_and_tag

          result = @first_build = @ra.build_and_move_to_store("./tweak.sh", PATTERN)
          puts ">>> #{result}, \n#{result[:hash_and_tag]}"
          info = result[:build_info]
          new_hash_and_tag = info[:hash_and_tag]
          new_hash_and_tag.should_not eql(initial_hash_and_tag)
          new_hash_and_tag.tag.should eql("v0.0.2")
        end

      end
    end



end
end
