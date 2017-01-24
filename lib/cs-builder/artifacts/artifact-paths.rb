module CsBuilder
  module Artifacts
    module ArtifactPaths

      def self.mk(org, repo, app_version, hash_and_tag, extname: ".tgz")
        extname = extname.start_with?(".") ? extname : ".#{extname}"
        "#{org}/#{repo}/#{app_version}/#{hash_and_tag.to_simple}#{extname}"
      end
    end
  end
end