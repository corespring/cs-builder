require_relative '../log/logger'
require_relative '../in-out/file-lock'
require_relative '../templates'
require_relative '../heroku/slug-builder'

module CsBuilder
  module Heroku
    module SlugFromTemplate

      extend CsBuilder::InOut::FileLock
      
      @@log = CsBuilder::Log.get_logger('slug-from-template')

      def self.mk_slug(artifact, out_path, template, templates_dir, force)


        @@log.debug "[mk_slug] artifact: #{artifact}, out_path: #{out_path}, template: #{template}, templates_dir: #{templates_dir}, force: #{force}"
        stack_archive = Templates.new(templates_dir).get_archive_path(template)
        with_file_lock(artifact){
          slug_path = CsBuilder::Heroku::SlugBuilder.mk_slug(
            stack_archive, 
            artifact, 
            out_path, 
            force: force)

          raise "slug_path: #{slug_path} doesn't match output: #{out_path}" if slug_path != out_path
          slug_path
        }

      end
    end
  end
end