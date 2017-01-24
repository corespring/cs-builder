require 'cs-builder/heroku/heroku-description'
require 'json'

include CsBuilder::Heroku 

describe CsBuilder::Heroku::HerokuDescription do 

  describe "==" do 

    it "should be false if the hashes are different" do 
      a = {:app => "0.60.1-SNAPSHOT",:hash => "8495e02",:tag => nil}.to_json
      b = {:app => "0.60.1-SNAPSHOT",:hash => "XXXXXX",:tag => nil}.to_json
      are_equal = HerokuDescription.from_json_string(a) == HerokuDescription.from_json_string(b)
      are_equal.should be(false)
    end
  end
end
