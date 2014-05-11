# Writing formulas

Formulas are scripts that are run on the end users machine to build a template.
They are usually run once and thereafter the built template will be used.

Templates make up one part of a heroku slug (the other have is the project's build assets). This means that they need to have a structure that will allow the slug to run once deployed to heroku.

The main thing that the template will need is the runtime that will run the app code.

Install this at the root of the folder. You can then update the PATH so that the runtime gets picked up.

The main thing to remember is the mapping between the template root and it's eventual destination in the slug.

if you install something at the root of the archive - it's destination will be /app/

eg:

    ./hello.txt ---> /app/hello.txt

To export the runtime on the PATH add a shell script here:

    ./.profile.d/export.sh
