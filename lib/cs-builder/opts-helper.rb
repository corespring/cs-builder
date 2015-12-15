require 'thor'


module OptsHelper 


  def self.symbols(h)
    c = h.clone
    puts "H? #{c}"
    if c.nil?
      raise "hash is nil?"
    else 
      out = c.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      out
    end
  end

  def inner_merge(hashes, acc)
    if(hashes.length == 0)
      acc
    else 
      acc = acc.merge(hashes.shift)
      inner_merge(hashes, acc)
    end
  end

  def merge(*hashes)
    inner_merge(hashes, {})
  end

  def add_opts(scope, *opts)
    merged = merge(*opts)
    merged.each{ |k,v| 
      scope[k] = Thor::Option.new(k, v)
    }
  end

  def str(d: "", r:false, f: nil)
    {:type => :string, :required => r, :desc => d, :default => f}
  end

  def org_repo(required, override: false)
    { 
      :org => str(r: required, d: "#{override ? "override " : ""}the org"),
      :repo => str(r: required, d: "#{override ? "override " : ""}the repo")
    } 
  end
end
