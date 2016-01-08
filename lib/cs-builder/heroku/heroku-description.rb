require 'json'

require_relative '../log/logger'

module CsBuilder
  module Heroku
    class HerokuDescription

      def initialize(app, hash, tag)
        @log = CsBuilder::Log.get_logger("heroku-description")
        @app = app
        @hash = hash
        @tag = tag
      end

      def ==(other)
        begin
          other.json_string == self.json_string
        rescue
          false
        end
      end

      def json_string
        {:app => @app, :hash => @hash, :tag => @tag}.to_json
      end

      def to_s
        self.json_string
      end

      def self.from_json_string(s)
        log = CsBuilder::Log.get_logger("heroku-description")
        begin
          json = JSON.parse(s)
          out = HerokuDescription.new(json["app"], json["hash"], json["tag"])
          log.debug("parsed #{s} to #{out}")
          out
        rescue => e
          log.warn(e)
          log.warn("Failed to parse string as json: #{s}, #{s.class.name}")
          nil
        end
      end
    end
  end
end
