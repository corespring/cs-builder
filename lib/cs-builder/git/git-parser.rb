module CsBuilder

  module Git
    
    module GitUrlParser

      REGEX = /git@.*?:(.*?)\/(.*?).git/

      def self.org(s)
        m = REGEX.match(s)
        m[1]
      end

      def self.repo(s)
        m = REGEX.match(s)
        m[2]
      end
    end

  end

end
