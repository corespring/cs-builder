module CsBuilder
  module Heroku

    module SlugHelper

      require 'yaml'

      # Get a hash from the Procfile yml file
      #
      def self.processes_from_slug(slug, procfile: "Procfile")
        final_path = "./app/#{procfile}"
        `tar -zxvf #{slug} #{final_path}`
        proc_yml = YAML.load_file(final_path) 
        FileUtils.rm_rf final_path 
        proc_yml
      end
  end
  end
end
