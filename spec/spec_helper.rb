require 'cs-builder/log/logger'
require 'dotenv'
require 'aws-sdk'
require 'pry-byebug'


Dotenv.load

Aws.config.update({
  region: 'us-east-1',
})

log_file = File.expand_path("spec/log-config.yml")
CsBuilder::Log.load_config(log_file) if File.exists?(log_file)

def get_logger(name)
  CsBuilder::Log.get_logger(name)
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
