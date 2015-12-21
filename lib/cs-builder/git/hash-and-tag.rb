module CsBuilder
  module Git

    HashAndTag = Struct.new(:hash, :tag) do 
     
      def self.from_simple(s)
        if(s.include?("-"))
          m = s.match(/(.*)-(.*)/)
          HashAndTag.new(m[2], m[1])
        else
          HashAndTag.new(s, nil)
        end
      end
      
      def to_s
        to_simple
      end 

      def to_simple
        if(tag.nil? or tag.empty?)
          hash
        else
          "#{tag}-#{hash}"
        end
      end
    
    end
  end
end
