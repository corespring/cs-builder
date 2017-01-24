#!/usr/bin/env bash

# see: https://devcenter.heroku.com/articles/platform-api-reference#ranges
# curl -i -n -X GET https://api.heroku.com/apps \
# -H "Accept: application/vnd.heroku+json; version=3" -H "Range: name ..; order=desc;"

token=$(heroku auth:token)
#https://devcenter.heroku.com/articles/platform-api-reference#release-info
curl -n -X GET https://api.heroku.com/apps/corespring-app-qa/releases \
-H "Authorization: Bearer $token" \
-H "Range: version; order=desc,max=10;" \
-H "Accept: application/vnd.heroku+json; version=3"