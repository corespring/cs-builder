require_relative '../log/logger'
require_relative '../in-out/file-lock'
require_relative '../in-out/archive'

module CsBuilder
  module Heroku

     module SlugBuilder

      extend CsBuilder::InOut::FileLock
      include CsBuilder::InOut
      
      @@log = CsBuilder::Log.get_logger('slug-builder')

      def self.check_file(path)
        raise "#{path} doesn't exist" unless File.exists?(path)
      end

      def self.mk_slug(stack, artifact, out_path, force: false)
        @@log.info("building slug..")
        @@log.debug("stack: #{stack}, artifact: #{artifact}, out_path: #{out_path}")

        raise "out_path must end with .tgz" if File.extname(out_path) != ".tgz"
        
        check_file(artifact)
        check_file(stack)

        if force
          @@log.debug("[force=true] removing: #{out_path}")
          FileUtils.rm_rf(out_path, :verbose => @@log.debug?)
        end

        if File.exists?(out_path) and !force
          @@log.warn "File #{out_path} already exists - skipping"
          out_path
        else
          with_file_lock(artifact){
            opts = {:force => force, :root_dir => "app"}
            Archive.merge(out_path, opts, stack, artifact)
          }
        end
      end
    end
  end
end