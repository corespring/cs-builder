require 'cs-builder/artifacts/store/local-store'
require 'cs-builder/git/repo'
require 'cs-builder/init'
require_relative '../../helpers/integration'

include CsBuilder::Artifacts
include CsBuilder::Git

describe CsBuilder::Artifacts::LocalStore do

  include Helpers::Integration

  before(:all) do
    CsBuilder::Log.set_config({
      "repo-local-store-spec" => "info",
      "local-store" => "info"

      })
    @log = get_logger("repo-local-store-spec")
  end

  def init
    @root = Dir.mktmpdir("repo_local_store")
    @archive = mk_dummy_archive("main")
    @hash_and_tag = HashAndTag.new("hash", "tag")
    @log.debug("@root: #{@root}")
  end

  before(:each) do
    init
    @ls = LocalStore.new(@root)
    @result = @ls.move_to_store(@archive, "org", "repo", "1.0", @hash_and_tag, ".tgz")
  end

  describe "artifact" do

    it "finds the artifact" do
      @ls.artifact("org", "repo", @hash_and_tag).nil?.should be(false)
    end

    it "should return :path" do
      expected_path = "org/repo/1.0/#{@hash_and_tag.to_simple}.tgz"
      result = @ls.artifact("org", "repo", @hash_and_tag)
      result[:path].should eql(expected_path)
    end

    it "should return :hash_and_tag" do
      result = @ls.artifact("org", "repo", @hash_and_tag)
      result[:hash_and_tag].should eql(@hash_and_tag)
    end

    it "should return :version" do
      result = @ls.artifact("org", "repo", @hash_and_tag)
      result[:version].should eql("1.0")
    end
  end

  describe "has_artifcat?" do
    it "should return true for an existing artifact" do
      @ls.has_artifact?("org", "repo", @hash_and_tag).should be(true)
    end

    it "should return false for a non existent artifact" do
      @ls.has_artifact?("org", "repo", HashAndTag.new("h", "t")).should be(false)
    end
  end

  describe "move_to_store" do

    it "returns :moved => true" do
      @result[:moved].should be(true)
    end

    it "moves the archive to the store" do
      expected_path = "#{@root}/org/repo/1.0/#{@hash_and_tag.to_simple}.tgz"
      File.exist?(expected_path).should be(true)
    end

    it "returns :moved => false if file exists and force is false" do
      second_archive = mk_dummy_archive("two")
      second_result = @ls.move_to_store(second_archive, "org", "repo", "1.0", @hash_and_tag, ".tgz")
      second_result[:moved].should be(false)
    end

    it "returns :moved => true if file exists and force is true" do
      second_archive = mk_dummy_archive("two")
      second_result = @ls.move_to_store(second_archive, "org", "repo", "1.0", @hash_and_tag, ".tgz", force:true)
      second_result[:moved].should be(true)
    end

    skip "should be the size of the moved archive" do
      second_archive = mk_archive("two")
      size = second_archive.size
      @log.debug("a: #{second_archive}, size: #{size}")
      second_result = @ls.move_to_store(second_archive, "org", "repo", "1.0", @hash_and_tag, ".tgz", force:true)
      @log.debug("result: #{second_result}")
      second_result[:path].size.should eql(size)
    end

  end
end
