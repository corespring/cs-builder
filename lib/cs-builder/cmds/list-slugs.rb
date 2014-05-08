require_relative './core-command'

module CsBuilder
  module Commands

    class ListSlugs < CoreCommand

      def initialize(level, config_dir)
        super('list_slugs', level, config_dir)
      end

      def run(options)
        "... coming... "
      end
    end
  end
end
