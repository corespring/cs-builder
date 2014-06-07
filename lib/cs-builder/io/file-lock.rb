module CsBuilder

  module Io
 
    module FileLock
      def with_file_lock(path)
        raise "File doesn't exist #{path}" unless File.exists?(path)
        file = File.open(path, File::RDWR|File::CREAT, 0644)
        file.flock(File::LOCK_EX)
        begin
          yield
        rescue => e
          raise e
        ensure
          puts "releasing: #{path}"
          file.flock(File::LOCK_UN)
        end
      end
    end
  end
end
