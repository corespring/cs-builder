`build-from-file` will copy a local folder, build and create an archive of `build_assets`.
--

It uses the org/repo/branch naming convention so these need to be passed in as params.

steps

* copy the folder to org/name/branch (you need to specify these) 

* run the `cmd` which is expected to build the project

* create an archive here:

-- binaries/org/repo/branch/uid.tgz

* return the path to the archive on completion.
