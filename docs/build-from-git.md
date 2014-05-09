`build-from-git` will clone if needed, build and create an archive of `build_assets`.

--

steps:

* git clone the project/branch if needed

* update the project

* run the `cmd` which is expected to build the project

* create an archive here:

 -- binaries/org/repo/branch/commit_hash.tgz

* return the path to the archive on completion.