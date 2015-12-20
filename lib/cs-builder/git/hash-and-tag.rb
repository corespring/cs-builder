module CsBuilder
  module Git

    class HashAndTag
      attr_accessor :hash, :tag
      def initialize(hash, tag = nil)
        @hash = hash
        @tag = tag
      end

      def to_simple
        if(tag.nil? or tag.empty?)
          @hash
        else
          "#{@tag}-#{@hash}"
        end
      end

      def to_s
        self.to_simple
      end

      def ==(other)
         self.to_simple == other.to_simple
      end

      def self.from_simple(s)
        if(s.include?("-"))
          m = s.match(/(.*)-(.*)/)
          HashAndTag.new(m[2], m[1])
        else
          HashAndTag.new(s)
        end
      end

    end
  end
end
