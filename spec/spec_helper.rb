require 'cs-builder/log/logger'

log_file = File.expand_path("spec/log-config.yml")
CsBuilder::Log.load_config(log_file) if File.exists?(log_file)

def get_logger(name)
  CsBuilder::Log.get_logger(name)
end
