`build-from-git` will clone if needed, run the build command and if you have specified `build_assets` will create an archive of those assets.

--

steps:

* git clone the project/branch if needed

* update the project

* run the `cmd` which is expected to build the project

* if build_assets is defined - create an archive here:

 -- binaries/org/repo/branch/commit_hash.tgz

* return the path to the archive on completion.
