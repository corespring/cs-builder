require_relative '../../helpers/integration'
require 'cs-builder/cmds/artifacts/mk-from-git'
require 'cs-builder/artifacts/store/remote-and-local-store'

include CsBuilder::Artifacts 

module Helpers
  module Deploy

    include Helpers::Integration

    def init_example(example_project, extra_cmds: nil)

      heroku_app = ENV["TEST_HEROKU_APP"]
      @log = CsBuilder::Log.get_logger("deploy-from-branch-spec")
      @log.debug("heroku_app: #{heroku_app}")

      @result = prepare_tmp_project(example_project)
      @store = RemoteAndLocalStore.build(File.join(@result[:config_dir], "artifacts"), bucket_name: "deploy-from-branch-spec")

      @deploy_opts = {
        :platform => "node-4.2.3",
        :heroku_app => heroku_app,
        :heroku_stack => "cedar-14",
        :procfile => "package/Procfile"
      }

      @cmds = <<-EOF
        git init
        git add .
        git commit . -m "first commit"
      EOF

      @cmds = @cmds + extra_cmds unless extra_cmds.nil?

      run_shell_cmds(@result[:project_dir], @cmds)

      @paths = Paths.new(@result[:config_dir], "org", "test-repo", "branch")
    end


    def build_artifact
      mk = MkFromGit.new(@result[:config_dir], @store)
      mk.run({
        :git => @result[:project_dir],
        :org => "org",
        :repo => "test-repo",
        :branch => "master",
        :cmd  => "npm pack",
        :artifact => "node-4.2.3-(.*).tgz"
      })
    end
  end
end