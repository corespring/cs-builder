require_relative './log/logger'
require_relative './in-out/utils'

module CsBuilder
  module Init

    extend CsBuilder::InOut::Utils

    Default_Config = "#{File.expand_path(File.dirname(__FILE__))}/../../.default-config/."

    @@log = CsBuilder::Log.get_logger('init')
    
    def self.init_cs_builder_dir(dir)

      full_dir = File.expand_path(dir)
      if(dir_inited?(full_dir))
        @@log.debug "dir already exists - no need to create it"
      else
        @@log.debug "dir doesn't exist - #{full_dir}"
        @@log.debug("mkdir: #{full_dir}")
        FileUtils.mkdir_p(full_dir)
        FileUtils.cp_r(Default_Config, full_dir)
      end

      # create some dirs if needed
      mkdir_if_needed(File.join(full_dir, "repos") )
      mkdir_if_needed(File.join(full_dir, "slugs") )
      mkdir_if_needed(File.join(full_dir, "binaries") )
      mkdir_if_needed(File.join(full_dir, "artifacts") )
    end

    def self.dir_inited?(dir)
      File.exists?(dir)
    end
  end
end