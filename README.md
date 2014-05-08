# cs-builder

A command line tool for cloning, compiling and deploying software.

## Setup

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
            ├── _jdk.formula

### binaries

This is where the compilation assets are stored using the /org/repo/branch/commit_hash
naming convention.

### repos

This is where the source code lives. These are git repositories. For each branch we create a new folder.

The compilation happens at the root of these folders

### slugs

These are where the heroku slugs live using the org/repo/branch/commit_hash
naming convention. A slug is a template.tgz ++ a binary.tgz.

### installation

    cd cs-builder
    gem install bundler
    bundle install
    rake build
    gem install pkg/cs-builder-0.0.1.gem

### developing

    bundle exec bin/cs-builder

### How it works

    cs-builder #-> outputs the list of available commmands

    cs-builder help cmd #-> more detailed help for the command

