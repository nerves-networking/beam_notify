# Changelog

## v0.2.1

This release only cleans up Makefile prints and bumps dependencies. No code
changes were made.

## v0.2.0

* New features
  * Support for explicitly passing the socket path - this enables use in
    restricted environments where it's impossible or hard to pass parameters
    through environment variables
  * Reporting the environment is off by default. See the `:report_env` option
  * Default socket paths are obfuscated. This also removes OS-specific
    character-set issues and length limitations

## v0.1.0

Initial release to hex.
