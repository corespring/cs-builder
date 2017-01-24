require 'platform-api'
require 'pp'
require 'json'

opts = {
 "Range" => "version; order=desc,max=20;" 
}

heroku = PlatformAPI.connect_oauth(`heroku auth:token`.chomp, default_headers: opts)
list = heroku.release.list('corespring-app-qa')

with_slug = list.find{ |o| 
  # !o["slug"].nil?
  puts o["version"]
  o["version"] == 1946
}

pp(with_slug)