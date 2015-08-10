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
    
### Configuration

#### Heroku

HEROKU_AUTH_TOKEN (optional) if not present will use `heroku auth:token`

**Migrating existing Heroku apps to new stack**

To set an app to run on a different stack do:

    heroku stack:set stack-name --APP cs-my-cool-feature

After the new stack has been set Heroku will prepare the rest when the next deployment happens.
`cs-builder` supports stack change when run in the `heroku-deploy-slug` mode through a command line argument `--stack=stack_name`

This `stack_name` parameter has to be the same as the one used above with the `heroku stack:set` command

### developing

    bundle exec bin/cs-builder


### Tests

#### Unit 
for Unit tests you'll want to override the env var: `TEST_HEROKU_APP` and `TEST_HEROKU_STACK`  
`TEST_HEROKU_STACK` **needs to be different from the stack of the** `TEST_HEROKU_APP`.  
_This will be the new stack Heroku will migrate the app after the successful deploy._
(Otherwise the unit test `deploy-heroku_spec` will fail 1 example out of the 4)

    rspec spec/unit
    
    
#### Integration

for integration tests you'll want to override the env var: `TEST_HEROKU_APP`

You'll want to run the integration tests specifically (it'll break if you don't): 

    rspec spec/integration/node-example-project_spec.rb


### How it works

    cs-builder #-> outputs the list of available commmands

    cs-builder help cmd #-> more detailed help for the command

### Workflow with CI

* scm change
  -> build "play test" #just test the app
  -> build "play stage" #stage app
  -> build prep build_assets
  -> make-slug
  -> deploy-slug

## Todo

* timings of commands
* command line docs
* deployment working - app working
* slug tidy up
* any commit_hash can make a build (checkout a new folder for the hash if it isn't HEAD - toss if after?)
* concurrent builds - fail if process already in place
