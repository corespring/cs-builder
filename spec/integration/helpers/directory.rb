module Helpers
  module Directory

    def self.entries(path)
      ::Dir.entries(path).reject{|p| p == "." or p == ".."}
    end
  end
end