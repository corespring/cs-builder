module Helpers
  module Dir

    def self.entries(path)
      ::Dir.entries(path).reject{|p| p == "." or p == ".."}
    end
  end
end