`make-artifact-git` is used to create an artifact from your project and place it in the cs-builder artifacts directory in the form: `cs-builder/artifacts/org/repo/version/(tag?-)sha.tgz`.

The --cmd option is a command that will be run against your project. It is expected that this command will generate a tgz archive that contains everything needed to run your app.

The --artifact option specifies where to find the artifact after the --cmd has been run. You may use a regex pattern with one group in it to match the artifact. This is because you may know the name of your artifact but if it's version is changing the regex will find it.

For example if you have a project that creates: 

    > my-app-1.0.tgz

And you have an --artifact option of: 

    > my-app-(.*).tgz

`make-artifact-git` will find the tgz and will automatically derive the version from the tgz name.

The --git option, specifies the repo from which to clone from. It is also used to derive the `org` and `repo` name if they aren't specified.

The --branch option specifies which branch to checkout before running the `--cmd`.

