require 'cs-builder/artifacts/store/s3-store'
require 'aws-sdk'
require 'cs-builder/log/logger'
require_relative '../../helpers/integration'

include CsBuilder::Artifacts

describe CsBuilder::Artifacts::S3Store do

  include Helpers::Integration

  CsBuilder::Log.set_config({
    "s3-store" => "warn",
    "s3-store-spec"=> "debug"})

  @log = CsBuilder::Log.get_logger('s3-store-spec')

  before(:each) do
    Aws.config.update({
      region: 'us-east-1',
    })

    @s3 = Aws::S3::Client.new
    bucket_name = "s3-store-spec-bucket"
    @b = Aws::S3::Bucket.new(bucket_name)
    @b.delete! if @b.exists?
    @store = S3Store.new(bucket_name, "cs-builder-artifacts", @s3)
  end

  describe "artifacts_from_key" do
    before(:each) do
      @store.mv_path(mk_dummy_archive("a"), "org/repo/0.1/a.tgz")
      @store.mv_path(mk_dummy_archive("b"), "org/repo/0.1/b.tgz")
    end

    it "finds 1 items for 'a'" do
      @store.artifacts_from_key("org", "repo", "a").should eql([
        "org/repo/0.1/a.tgz"
      ])
    end

    it "finds 1 items for 'b'" do
      @store.artifacts_from_key("org", "repo", "b").should eql([
        "org/repo/0.1/b.tgz"
      ])
    end

    it "finds 2 items for '0.1'" do
      @store.artifacts_from_key("org", "repo", "0.1").should eql([
        "org/repo/0.1/a.tgz",
        "org/repo/0.1/b.tgz"
      ])
    end
  end

  describe "mv_path" do

    before(:each) do
      @archive = mk_dummy_archive("s3")
    end

    it "puts the file on s3" do
      @store.mv_path(@archive, "org/repo/0.1/hash.tgz")
      @store.path_exists?("org/repo/0.1/hash.tgz").should be(true)
    end

    it "throws an error if a file exists already and force == false" do
      @store.mv_path(@archive, "org/repo/0.1/hash.tgz")
      lambda {
        @store.mv_path(mk_dummy_archive("dummy"), "org/repo/0.1/hash.tgz")
      }.should raise_error(@store.file_exists_error_msg("org/repo/0.1/hash.tgz"))
    end

    it "move the file if file exists already and force == true" do
      @store.mv_path(@archive, "org/repo/0.1/hash.tgz")
      @store.mv_path(mk_dummy_archive("dummy"), "org/repo/0.1/hash.tgz", :force => true)
      @store.path_exists?("org/repo/0.1/hash.tgz").should be(true)
    end

    it "removes the local file" do
      @store.mv_path(@archive, "org/repo/0.1/hash.tgz")
      File.exist?(@archive).should eql(false)
    end
  end
end
