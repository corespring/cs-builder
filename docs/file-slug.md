`file-slug` will create a heroku compatible slug using binaries and a slug template.

You pass in org, repo, branch and uid so it knows which binary to use.
--

steps:


* check to see if there is a binary with the uid in 'binaries'

* check to see if there is a template ready

** if not install the template using the formula

* expand the template and binaries to one folder

* compress archive into a heroku compatible slug

* return the path to the slug  
