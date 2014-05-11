module CsBuilder
  module Heroku

    module SlugHelper

      require 'yaml'

      # Get a hash from the Procfile yml file
      #
      def self.processes_from_slug(slug)
        `tar -zxvf #{slug} ./app/Procfile`
        proc_yml = YAML.load_file('./app/Procfile')
        FileUtils.rm_rf './app/Procfile'
        proc_yml
      end
  end
  end
end
