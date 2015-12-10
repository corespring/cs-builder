require_relative 'core-command'
require_relative '../heroku/slug-from-template'

module CsBuilder
  module Commands
    class MakeSlugFromArtifact < CoreCommand 
      def initialize(config_dir)
        super('make-slug-from-artifact', config_dir)
      end

      def run(options)
        @log.info "[run] MakeSlug..."
        @log.debug "[run] options: #{options}"
        CsBuilder::Heroku::SlugFromTemplate.mk_slug(
          options[:artifact],
          options[:out],
          options[:platform],
          File.join(@config_dir, "templates"),
          options[:force])
      end
    end
  end
end