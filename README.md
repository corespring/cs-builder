# cs-builder

A command line tool for cloning, compiling and deploying software.

It's based on the ideas outlined [in this heroku article](https://devcenter.heroku.com/articles/platform-api-deploying-slugs).


Instead of using a buildpack to make the slug, it uses a `template` and the `binaries` from the project to make it.

The benefits of this approach is speed. You are compiling/prepping your project once, then the rest of the process is a matter of tarring and untarring some stuff together.

The drawbacks are that there may be build inconsistencies in the slug (for example - if you put jdk-1.6 with an app that was compiled with jdk-1.7).

However - if you know what you're doing these drawbacks can be overcome.

## Dependencies

* git
* heroku toolbelt if you want to deploy to heroku (plus an app you can deploy to)
* curl

## Setup

The gem creates its own configuration folder in your home dir. This contains the following diretories: `binaries`, `repos`, `slugs` and under these the data is stored using the `org/repo/branch/` format. It also contains a `templates` directory that contains `formulas` and `built`.

The first time you run the gem it'll create a folder `~/.cs-builder` that
looks like:

    .
    ├── binaries
    │   └── org
    │       └── repo
    │           └── branch
    ├── repos
    │   └── org
    │       └── repo
    │           └── branch
    ├── slugs
    │   └── org
    │       └── repo
    │           └── branch
    └── templates
        ├── built
        │   └── jdk-1.7.tgz
        └── formulas
            ├── jdk-1.6.formula
            ├── jdk-1.7.formula
            └── _jdk.formula

### binaries

This is where the compilation assets are stored using the /org/repo/branch/commit_hash
naming convention.

### repos

This is where the source code lives. These are git repositories. For each branch we create a new folder.

The compilation happens at the root of these folders

### slugs

These are where the heroku slugs live using the org/repo/branch/commit_hash
naming convention. A slug is a template.tgz ++ a binary.tgz.

### templates

These are slug templates, that are used to make slugs along with the `binaries`. If the template isn't built, and there's a formula for it, `cs-builder` will run the formula to install the template.

#### formulas

These are bash scripts that are run to create a built template. They are passed the path to the templates folder as the 1st (`$1`) parameter.


### installation

    cd cs-builder
    gem install bundler
    bundle install
    rake build
    gem install pkg/cs-builder-0.0.1.gem

### developing

    bundle exec bin/cs-builder


### Tests

#### Unit

    rspec spec/unit

#### Integration

    rspec spec/integration

Note that these tests will take a bit longer and you'll need override the env var: `TEST_HEROKU_APP`.


### Commands

    cs-builder #-> outputs the list of available commmands

    build-from-file    # copy a local project, build and create an archive
    build-from-git     # clone if needed, update, build and create an archive
    git-slug           # make a slug identified by a git repo
    heroku-deploy-slug # deploy a slug
    list-slugs         # list all slugs
    remove             # remove template
    remove-config      # remove the config dir

* removing binaries
* removing slugs

If you have hooked up `cs-builder` to a CI system it's going to be generating alot of binaries and slugs. For these systems you normally only want to hang on to the latest build per branch (aka `HEAD`), that can be used for deployment to various targets.


    1: build org/repo/branch#2 => binaries/org/repo/branch/2.tgz
      --> are there old binaries? (1.tgz)
      --> is being used? (1.tgz)
      ----> yes: leave it
      ----> no: delete it

    2: slug org/repo/branch#1 => slugs/org/repo/branch/1.tgz
      --> are there any old slugs (0.tgz)?
      --> is in use? (0.tgz)
      ----> yes: leave alone
      ----> no: delete it
      --> declare use of binaries 1.tgz (will prevent others from deleting it)
      --> complete action
      --> take lock off binaries:1.tgz

    3: deploy org/repo/branch#3 => ...
      --> declare use of slug:0.tgz
      --> complete action
      --> take lock off slug:0.tgz

You may also want to build + deploy an older commit. You don't want to keep the slug/binary after it's been deployed.

## Todo

* timings of commands
* command line docs
* deployment working - app working
* slug tidy up
* any commit_hash can make a build (checkout a new folder for the hash if it isn't HEAD - toss if after?)
* concurrent builds - fail if process already in place
