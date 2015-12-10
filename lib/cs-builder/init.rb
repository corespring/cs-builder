require_relative './log/logger'

module CsBuilder
  module Init

    Default_Config = "#{File.expand_path(File.dirname(__FILE__))}/../../.default-config/."

    @@log = CsBuilder::Log.get_logger('init')
    
    def self.init_cs_builder_dir(dir)

      if(dir_inited?(path))
        @@log.debug "dir already exists - no need to create it"
      else
        @@log.debug "dir doesn't exist - #{path}"
        @@log.debug("mkdir: #{path}")
        full_path = File.expand_path(path)
        FileUtils.mkdir_p(full_path)
        FileUtils.cp_r(Default_Config, full_path)
      end

      # create some dirs if needed
      mkdir_if_needed(File.join(full_path, "repos") )
      mkdir_if_needed(File.join(full_path, "slugs") )
      mkdir_if_needed(File.join(full_path, "binaries") )
      mkdir_if_needed(File.join(full_path, "artifacts") )
    end

    def self.dir_inited?(path)
      File.exists?(path)
    end
  end
end