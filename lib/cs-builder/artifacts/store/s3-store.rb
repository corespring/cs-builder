require_relative '../../log/logger'
require_relative './base-store'

module CsBuilder
  module Artifacts
    class S3Store < BaseStore


      def initialize(bucket, artifacts_root, s3)
        super()
        @log = CsBuilder::Log.get_logger("s3-store")
        @log.info("initialize")
        @bucket = bucket
        @artifacts_root = artifacts_root
        @s3 = s3
        init_bucket
      end

      def file_exists_error_msg(path)
        "File already exists at this path: #{path}, add :force => true to overwrite"
      end

      def mv_path(from, to, force: false)

        if(force)
          rm_path(to)
        end

        if(path_exists?(to) and !force)
          raise "File already exists at this path: #{to}, add :force => true to overwrite"
        else
          @log.debug("backing up to: #{to}, bucket: #{@bucket}")
          key = mk_key(to)
          File.open(from, 'rb') do |file|
            @s3.put_object(bucket: @bucket, key: key, body: file)
          end
          FileUtils.rm_rf(from)
        end
      end

      def rm_path(path)
        @log.debug("rm_path: #{path}")
        key = mk_key(path)
        @s3.delete_object({bucket: @bucket, key: key})
      end

      def path_exists?(path)
        key = mk_key(path)
        object_exists?(key)
      end

      ## list all artifacts
      def artifacts_from_key(org, repo, key)
        @log.debug("[artifacts_from_key] org: #{org}, repo: #{repo}, key: #{key} - call s3...")
        resp = @s3.list_objects({
          bucket: @bucket,
          max_keys: 50,
          prefix: "#{File.join(@artifacts_root, org, repo)}/"
        })

        @log.debug("[artifacts_from_key] org: #{org}, repo: #{repo}, key: #{key} - s3 response.contents: #{resp.contents}")

        cleaned = resp.contents.map{ |o|
          strip_path(o.key)
        }.select{ |k|
          k[/.*#{key}.*/]
        }
      end


      ## Return a local path to the archive
      ## Download it from s3 and put it in the tmp dir.
      def resolve_path(path)
        key = mk_key(path)
        @log.debug("pull, key: #{key}")
        basename = File.basename(path)
        local_path = File.join(Dir.tmpdir, "s3-store-downloads", basename)
        FileUtils.mkdir_p(File.dirname(local_path))
        @s3.get_object(bucket: @bucket, key: key, response_target: local_path)
      end

      private

      def mk_key(key)
        "#{@artifacts_root}/#{key}"
      end

      def strip_path(path)
        path.sub(/^#{@artifacts_root}\//, "")
      end

      def object_exists?(key)
        begin
          @s3.head_object({bucket: @bucket, key: key})
          @log.debug("object: #{key} *does* exist")
          true
        rescue => e
          @log.debug("object: #{key} doesn't exist")
          false
        end
      end

      def init_bucket
        create_if_needed
      end

      def create_if_needed
        begin
          response = @s3.head_bucket({bucket: @bucket})
          @log.debug("bucket exists: #{response}")
        rescue => e
          @log.debug("e: #{e} - creating bucket")
          @s3.create_bucket({
            acl: "private",
            bucket: @bucket
          })
        end
      end
    end
  end
end
