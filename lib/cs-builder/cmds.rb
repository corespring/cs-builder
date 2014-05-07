require 'log4r'

module CsBuilder

  module Commands

    class CoreCommand

      include Log4r
      
      def initialize(name, level: Log4r::INFO)
        @log = Log4r::Logger.new(name) 
        @log.outputters << Log4r::StdoutOutputter.new('log_stdout') #, :level => Log4r::WARN )
        @log.level = level 
        @log.info("Creation")
        #init_build_dir
      end
    end

    class Build < CoreCommand

      def initialize(level)
        super.initialize('build')
      end

      def run(options)
      end
    end
  end
end

