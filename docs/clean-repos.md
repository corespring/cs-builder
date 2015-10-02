`clean-repos` will clean up slugs and repositories older than a spcified number of days

--

Optional flags:

* --older_than_days (string)
default: 7
the --older_than_days parameter will tell cs-builder what repositories and slugs to clean up based on their creation date.
Example:
--older_than_days=5
will delete repositories and slugs that are older than 5 days

* --slugs (boolean)
default: true
By default, cs-builder will look for old slugs to clean up too
Change it to `false` to turn this feature off, so clean-repos will only delete old repositories