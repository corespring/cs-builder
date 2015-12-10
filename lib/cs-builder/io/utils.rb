module CsBuilder
  module IO
    module Utils
      
      def in_dir(dir)
        current = File.expand_path(Dir.pwd)
        Dir.chdir(dir)
        @log.debug("[in_dir] current dir #{Dir.pwd}")
        yield
        Dir.chdir(current)
        @log.debug("[in_dir] back to: #{Dir.pwd}")
      end

      def mkdir_if_needed(p)
        unless File.directory? p
          FileUtils.mkdir(p)
        end
      end

    end
  end
end