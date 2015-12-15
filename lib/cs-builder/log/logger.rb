module CsBuilder
  module Log 

    require 'log4r'
    require 'yaml'

    include Log4r

    def self.str_to_log_level(s)
      case s.upcase
      when "FATAL"
        return 5
      when "ERROR"
        return 4
      when "WARN"
        return 3
      when "INFO"
        return 2
      when "DEBUG"
        return 1
      else
        return 2
      end
    end

    @@log_config = {
      "default" => self.str_to_log_level("FATAL"),
    }

    @@loggers = {}

    Log4r.define_levels(*Log4r::Log4rConfig::LogLevels)
  
    def self.set_config(cnf)
      cnf.each{ |k,v|
        @@log_config[k] = self.str_to_log_level(v)
      }

      @@loggers.each{ |k,v| 
        l = @@log_config[k] || @@log_config["default"]
        v.level = l 
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

      format = PatternFormatter.new(:pattern => "[%l] [%c] %m")
      if @@loggers[name].nil?
        log_level = @@log_config[name] || @@log_config["default"]
        @@loggers[name] = Log4r::Logger.new(name)
        @@loggers[name].outputters << Log4r::Outputter.stdout
        @@loggers[name].outputters.each{ |o|
          o.formatter = format
        }
        @@loggers[name].level = log_level
      end

      @@loggers[name]
    end
end
end