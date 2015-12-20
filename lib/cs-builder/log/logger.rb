
require 'logging'

module CsBuilder
  module Log

    require 'yaml'

    @@default = "error"

    @@config = {}

    def self.set_config(cnf)
      puts "cnf: #{cnf}"
      @@config = cnf
      @@default = @@config["default"] unless @@config["default"].nil?
      @@config.each{ |k,v|
        Logging.logger[k].level = v
      }
    end

    def self.load_config(path)

      full_path = File.expand_path(path)

      if File.exists? full_path
        puts "full path: #{full_path}"
        cnf = YAML::load_file(full_path)
        set_config(cnf)
      else
        puts "Failed to load log config from: #{full_path}"
      end
    end

    def self.get_logger(name)
      l = Logging.logger[name]
      l.add_appenders \
        Logging.appenders.stdout
      l.level = @@config.has_key?(name) ? @@config[name] : @@default
      l
    end
  end
end
