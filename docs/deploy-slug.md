`heroku-deploy-slug` will deploy a previously created heroku compatible slug and trigger a release on Heroku.

--

Optional flags:

* --stack (string)
default: "cedar-14"
using the --stack flag one can set what stack to use on the Heroku app


* --cleanup (boolean)
default: false
Using --cleanup flag instructs cs-builder to delete the slug file it deployed on Heroku and the repository it created to build the slug.
Note: this will free up some space especially when the slug / repository is big, however it fill slow down future builds as they will have to clone the remote repository again.
Only use with one off deploys (release, hotfix)