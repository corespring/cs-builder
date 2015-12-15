require_relative '../log/logger'

module CsBuilder
  module InOut
    module Utils
      
      def in_dir(dir)
        @@log = CsBuilder::Log.get_logger("in_dir")       
        current = File.expand_path(Dir.pwd)
        Dir.chdir(dir)
        @@log.debug("current dir #{Dir.pwd}")
        yield
        Dir.chdir(current)
        @@log.debug("back to: #{Dir.pwd}")
      end

      def mkdir_if_needed(p)
        unless File.directory? p
          FileUtils.mkdir(p)
        end
      end

    end
  end
end