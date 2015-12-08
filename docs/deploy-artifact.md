`deploy-artifact` will look for an artifact, blend the artifact with a formula to make a slug and then deploy the slug to herkou.

This command is used in conjunction with `make-artifact-git`.

If you provide --git and --branch, it'll look for an artifact that matches the head of that branch. That may be a tag like: v1.0.0 or a git sha. 

If you provide --git and --version, it'll look for an artifact that has a version match to this version.

The command will not deploy to heroku if the version/sha you want to deploy has already been deployed and --force is false.

--artifact-format is to ??? 

--
