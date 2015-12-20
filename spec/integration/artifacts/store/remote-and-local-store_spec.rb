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

  before(:each) do
   CsBuilder::Log.set_config({
     "s3-store" => "debug",
     "s3-store-spec"=> "debug"})

    @log = CsBuilder::Log.get_logger("remote-and-local-store-spec")
    @log.info("info")
    bucket_name = "s3-store-spec-bucket"

    @b = Aws::S3::Bucket.new(bucket_name)
    @b.delete! if @b.exists?

    tmp_dir = Dir.mktmpdir(bucket_name)
    local_root = File.join(tmp_dir, "artifacts")
    @store = RemoteAndLocalStore.build(local_root, bucket_name: bucket_name)
  end

  describe "initialize" do
    it "should not be nil" do
      @store.nil?.should be(false)
    end
  end

end
