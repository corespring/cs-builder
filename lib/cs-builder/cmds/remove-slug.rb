require_relative './core-command'

module CsBuilder
  module Commands
    class RemoveTemplate < CoreCommand

      def initialize(level, config_dir)
        super('remove_templates', level, config_dir)
      end

      def run(options)
        name = options[:template]
        path = "#{@config_dir}/templates/built/#{name}.tgz"
        @log.debug "removing #{path}"
        FileUtils.rm_rf(path, :verbose => true) if File.exists? path
        @log.warn "#{path} doesn't exist" unless File.exists? path
      end
    end
  end
end
