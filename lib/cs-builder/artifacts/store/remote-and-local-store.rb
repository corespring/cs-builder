require_relative '../../log/logger'
require_relative './base-store'
require_relative '../../git/hash-and-tag'
require 'aws-sdk'
require_relative  '../../bucket'
require_relative './s3-store'
require_relative './local-store'

include CsBuilder::Git
include CsBuilder::Log

module CsBuilder
  module Artifacts

    # A store that uses a local file store and a remote store
    class RemoteAndLocalStore < BaseStore

      def self.build(local_path, bucket_name: CsBuilder::BUCKET)
        Aws.config.update({
          region: 'us-east-1',
        })
        s3 = Aws::S3::Client.new
        root = File.basename(local_path)
        FileUtils.mkdir_p(local_path)
        remote_store = S3Store.new(bucket_name, root, s3)
        local_store = LocalStore.new(local_path)
        RemoteAndLocalStore.new(remote_store, local_store)
      end


      def initialize(remote, local, backup_tagged_archives: true)
        super()
        @log = Log.get_logger('remote-and-local-store')
        @remote = remote
        @local = local
        @backup_tagged_archives = backup_tagged_archives
      end

      def mv_path(from, to, force:false)
        @log.debug("[mv_path] #{from} -> #{to}, force: #{force}")

        @local.mv_path(from, to, force: force)
        if(@backup_tagged_archives and is_tagged(to))
          @remote.cp_path(@local.resolve_path(to), to, force: force)
        end
        to
      end

      def rm_path(path)
        @local.rm_path(path)
        @remote.rm_path(path)
      end

      def path_exists?(path)
        @local.path_exists?(path) or @remote.path_exists?(path)
      end


      ## Return a local path to the archive
      ## If the archive is remote, pull it down to the local path
      def resolve_path(path)

        if(!@local.path_exists?(path) and @remote.path_exists?(path))
          downloaded_path = @remote.resolve_path(path)
          destination = @local.resolve_path(path)
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.mv(downloaded_path, destination)
        end

        if(@local.path_exists?(path))
          @local.resolve_path(path)
        else
          nil
        end

      end

      def artifacts_from_key(org, repo, key)
        local_keys = @local.artifacts_from_key(org, repo, key)
        remote_keys = @remote.artifacts_from_key(org, repo, key)
        @log.debug("[artifacts_from_key] org: #{org}, repo: #{repo}, key: #{key}, local_keys: #{local_keys}, remote_keys: #{remote_keys}")
        out = (local_keys + remote_keys).uniq
        @log.debug("[artifacts_from_key] out: #{out}")
        out
      end

      private
      def is_tagged(path)
        hash_string = File.basename(path, ".tgz")
        ht = HashAndTag.from_simple(hash_string)
        tagged = !ht.tag.nil?
        @log.debug("[is_tagged?] path: #{path} - #{tagged}")
        tagged
      end

    end
  end
end
