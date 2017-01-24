require_relative '../log/logger'
require_relative './artifact-paths'
require_relative '../git/repo'

include CsBuilder::Log
include CsBuilder::Artifacts::ArtifactPaths
include CsBuilder::Git

module CsBuilder
  module Artifacts
    class ArtifactsBackup

      ROOT = "artifacts"

      @@log = Log.get_logger("artifacts-backup")

      def initialize(bucket, s3)
        @s3 = s3
        @bucket = bucket
        @@log.debug("bucket: #{@bucket}, s3: #{s3}")
        init_bucket
      end

      ### Backup an artifact
      def backup(org, repo, path:, hash_and_tag:, version:, extname: ".tgz", force: false)
        k = ArtifactPaths.mk(org, repo, version, hash_and_tag, extname: extname)
        key = "#{ROOT}/#{k}"

        if(object_exists?(key) and !force)
          @@log.debug("not backing up - the key: #{key}, already exists")
        else 
          @@log.debug("backing up to: #{key}, bucket: #{@bucket}")
          File.open(path, 'rb') do |file|
            @s3.put_object(bucket: @bucket, key: key, body: file)
          end
        end
      end

      ### List artifacts for org/repo
      def list(org, repo)
        prefix = "#{ROOT}/#{org}/#{repo}"
        response = @s3.list_objects({bucket: @bucket, prefix: prefix})
        @@log.debug("contents: #{response.contents}")
        response.contents.map(&:key).map{ |k|
          k.gsub(/^#{ROOT}\//, "")
        }
      end

      ### Download an artifact
      def download_tagged(org, repo, tag:, save_path:)

        @@log.debug("save_path: #{save_path}")
        FileUtils.mkdir_p(File.dirname(save_path))
        keys = list(org, repo)
        k = keys.find{ |k| 
          File.basename(k).start_with?(tag)
        }

        if k.nil?
          nil
        else 
          key = "#{ROOT}/#{k}"
          @@log.debug("downloading key: #{key} to: #{save_path}")
          @s3.get_object({bucket: @bucket, key: key, response_target: save_path})
          save_path
        end
      end
      
      private 

      def object_exists?(key)
        begin 
          @s3.head_object({bucket: @bucket, key: key})
          @@log.debug("object: #{key} *does* exist")
          true
        rescue => e 
          @@log.debug("object: #{key} doesn't exist")
          false
        end
      end

      def init_bucket
        create_if_needed
      end

      def create_if_needed
        begin 
          response = @s3.head_bucket({bucket: @bucket})
          @@log.debug(response)
        rescue => e
          @@log.debug("e: #{e} - creating bucket")
          @s3.create_bucket({
            acl: "private",
            bucket: @bucket
          })
        end
      end
    end
  end
end