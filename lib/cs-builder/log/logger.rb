module CsBuilder
  module Log 

    require 'log4r'
    include Log4r

    def self.included(base)
      add_logger(base)
    end

    def self.add_logger(base)
      name = base.to_s
      logger = Log4r::Logger[name] || Log4r::Logger.new(name)
      logger.outputters << Log4r::StdoutOutputter.new('log_stdout') #, :level => Log4r::WARN )
      logger.level = 1
      base.class_variable_set(:@@log, logger)
      base.class_eval do 
      def logger; self.class.logger; end
      def self.logger; class_variable_get(:@@log); end
    end
  end
  end
end