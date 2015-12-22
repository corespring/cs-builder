require 'cs-builder/artifacts/store/s3-store'
require 'cs-builder/artifacts/store/local-store'
require 'cs-builder/artifacts/store/remote-and-local-store'
require 'aws-sdk'
require 'cs-builder/log/logger'
require_relative '../../helpers/integration'

include CsBuilder::Artifacts
include CsBuilder

describe CsBuilder::Artifacts::RemoteAndLocalStore do

  include Helpers::Integration
  
  BucketName = "remote-and-local-store-spec-bucket"

  before(:each) do

    @log = CsBuilder::Log.get_logger("remote-and-local-store-spec")
    @log.info("info")

    @b = Aws::S3::Bucket.new(BucketName)
    @b.delete! if @b.exists?

    @s3 = Aws::S3::Client.new
    tmp_dir = Dir.mktmpdir(BucketName)
    @local_root = File.join(tmp_dir, "artifacts")
    @store = RemoteAndLocalStore.build(@local_root, bucket_name: BucketName)
  end

  after(:all) do 
    @b = Aws::S3::Bucket.new(BucketName)
    @b.delete! if @b.exists?
  end

  describe "initialize" do
    it "should not be nil" do
      @store.nil?.should be(false)
    end
  end

  describe "mv_path" do 

    before(:each) do 
      archive = mk_dummy_archive("blah")
      @store.mv_path(archive, "a/b/hash-tag.tgz")
    end

    it "moves the archive to the local store" do
      Dir["#{@local_root}/**/*.tgz"].should eql(["#{@local_root}/a/b/hash-tag.tgz"])
    end

    it "moves the archive to the remote store if it's tagged" do 
      resp = @s3.list_objects({bucket: BucketName})
      resp.contents.map{ |c| c.key }.should eql(["artifacts/a/b/hash-tag.tgz"])
    end
  end

  describe "resolve_path" do 

    before(:each) do 
      archive = mk_dummy_archive("blah")
      @store.mv_path(archive, "a/b/hash-tag.tgz")
      Dir["#{@local_root}/**/*.tgz"].each{|a|
        FileUtils.rm_rf(a)
      } 
    end

    it "downloads the archive from s3 and moves it to the local store" do 
      entries = Dir["#{@local_root}/**/*.tgz"].length.should eql(0)
      @store.resolve_path("a/b/hash-tag.tgz")
      Dir["#{@local_root}/**/*.tgz"].length.should eql(1)
    end
  end

  describe "artifact" do 
    
    it "returns artifact info" do 
      archive = mk_dummy_archive("blah")
      ht = HashAndTag.new("hash", "tag")
      @store.move_to_store(archive, "org", "repo", "0.1", ht)
      artifact = @store.artifact("org", "repo", ht)
      puts artifact
      @log.debug("artifact: #{artifact}")
      artifact.should include({
        :virtual_path => "org/repo/0.1/#{ht.to_simple}.tgz",
        :version => "0.1"
      })
    end

  end

  describe "list artifacts" do 

    def add_to_store(ht)
      archive = mk_dummy_archive("blah")
      @store.move_to_store(archive, "org", "repo", "0.1", ht)
      ht
    end

    before(:each) do 
      @ht_one = add_to_store(HashAndTag.new("hash", "tag"))
      @ht_two = add_to_store(HashAndTag.new("hash", nil))
    end

    it "returns a pretty list of artifacts" do 
      @store.list_artifacts("org", "repo").should eql([
        {:key => "org/repo/0.1/#{@ht_two.to_simple}.tgz", 
        :local => true,
        :remote => false},
        {:key => "org/repo/0.1/#{@ht_one.to_simple}.tgz", 
        :local => true, 
        :remote => true}
      ])
    end
    
    it "returns a pretty list of artifacts - returns only the remote artifact" do 

      Dir["#{@local_root}/**/*.tgz"].each{ |p|
        FileUtils.rm_rf(p)
      }

      @store.list_artifacts("org", "repo").should eql([
        {:key => "org/repo/0.1/#{@ht_one.to_simple}.tgz", 
        :local => false, 
        :remote => true}
      ])
    end
  end

end
