`git-slug` will create a heroku compatible slug using binaries and a slug template. 

--

steps: 

* get the commit_hash from the source repo 

* check to see if there is a binary with that commith_hash in 'repos'

* check to see if there is a template ready

** if not install the template using the formula

* expand the template and binaries to one folder

* compress archive into a heroku compatible slug

* return the path to the slug  
