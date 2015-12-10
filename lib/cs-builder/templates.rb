require_relative './log/logger'
require_relative './io/utils'
require_relative './shell/runner'

module CsBuilder
  class Templates

    include CsBuilder::ShellRunner
    include CsBuilder::IO::Utils

    def initialize(templates_dir)
      @log = CsBuilder::Log.get_logger('templates')
      @templates_dir = templates_dir
      @log.info("templates dir: #{@templates_dir}")
    end

    def get_archive_path(name)
      path = template_archive(name)
      if(exists?(path))
        path 
      else 
        install_template(name)
      end
    end

    private 

    def exists?(p) 
      File.exists?(p)
    end

    def install_template(name)
      @log.debug "need to install template, looking for a formla for #{name}"
      script = formula("#{name}.formula")
      raise "No formula found for #{script}" unless File.exists? script
      mkdir_if_needed(File.join(@templates_dir, "built"))
      in_dir(File.dirname(script)){
        File.chmod(0755, "#{name}.formula")
        @log.debug "running formula: #{name}.formula - this will install the template for #{name} - this is a one-time process ... please wait"
        run_shell_cmd "./#{name}.formula ../built"
      }
      raise "The formula didn't install the template correctly: #{name}" unless exists? template_archive(name)
      template_archive(name)
    end

    def formula(name)
      File.expand_path(File.join(@templates_dir, "formulas", name))
    end

    def template_archive(name)
      File.join(@templates_dir, "built", "#{name}.tgz")
    end
  end 
end