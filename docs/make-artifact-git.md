`make-artifact-git` will clone if needed, run the artifact command and will move the artifact to ~/.cs-builder/artifacts/org/name/version/sha.zip.

--

steps:

* git clone the project/branch if needed

* update the project

* run the `cmd` which is expected to build a project artifact (ie: a zip or jar)

* move the artifact to the artifacts directory
