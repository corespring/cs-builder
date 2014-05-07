require 'yaml'

module CsBuilder

  module ProcfileReader

    # Returns a hash from the yaml
    # 
    def self.processes(path)
      raise "Yaml file #{path} doesn't exist" unless File.exists? path
      proc_yml = YAML.load_file(path)
      puts proc_yml.class
      proc_yml
    end

  end

end
