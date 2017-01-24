require_relative '../log/logger'

module CsBuilder

  module InOut
 
    module FileLock

      @@log = CsBuilder::Log.get_logger('file-lock')

      def with_file_lock(path)
        @@log.debug("path: #{path}")
        raise "File doesn't exist #{path}" unless File.exists?(path)
        file = File.open(path, File::RDWR|File::CREAT, 0644)
        @@log.info( "locking: #{path} with #{File::LOCK_SH}")
        file.flock(File::LOCK_SH)
        begin
          yield
        rescue => e
          raise e
        ensure
          @@log.info( "releasing lock on: #{path}")
          file.flock(File::LOCK_UN)
        end
      end
    end
  end
end
