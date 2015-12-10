require_relative '../log/logger'
require_relative '../io/file-lock'
require_relative '../io/archive'

module CsBuilder
  module Heroku

     module SlugBuilder

      extend CsBuilder::Io::FileLock
      include CsBuilder::IO
      
      @@log = CsBuilder::Log.get_logger('slug-builder')

      def self.check_file(path)
        raise "#{path} doesn't exist" unless File.exists?(path)
      end

      def self.mk_slug(stack, artifact, out_path, force: false)
        @@log.info("building slug..")
        @@log.debug("stack: #{stack}, artifact: #{artifact}, out_path: #{out_path}")

        check_file(artifact)
        check_file(stack)

        FileUtils.rm_rf(out_path) if force

        if File.exists?(out_path) and !force
          @@log.warn "File #{output} already exists - skipping"
          out_path
        else
          with_file_lock(artifact){
            opts = {:force => force}
            Archive.merge(out_path, opts, stack, artifact)
          }
        end
      end
    end
  end
end