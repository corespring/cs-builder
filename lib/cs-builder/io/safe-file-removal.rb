module CsBuilder

  module IO

    module SafeFileRemoval

      def removal_log(msg)
        puts(msg)
      end

      def safely_remove_all_except(path)
        raise "File doesn't exist: #{path}" unless File.exists?(path)
        folder = File.dirname(path)
        removal_log("don't delete path: #{path}")
        removal_log(folder)
        Dir["#{folder}/*", "!#{path}"].each{ |f|
          removal_log("removing: #{f}") unless f == path
          safe_delete(f) unless f == path
        }
      end

      def safe_delete(path)
        unless flocked?(path)
          FileUtils.rm_rf(path)
        else
          removal_log("locked: #{path}")
        end
      end

      def flocked?(path)
        file = File.new(path)
        status = file.flock(File::LOCK_EX|File::LOCK_NB)
        case status
        when false
          return true
        when 0
          return false
        else
          raise SystemCallError, status
        end
      end
    end

  end
end
