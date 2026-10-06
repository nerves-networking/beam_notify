# Changelog

## v1.1.2

* Fixes
  * Fix parallel make compilation race
  * Mark a `:binary_to_term/2` call with `:safe` to avoid worrying about atom
    exhaustion. Under intended use, it doesn't get any atoms.

## v1.1.1

* Fixes
  * Fix compilation on systems with Erlang installed in a directory with spaces

## v1.1.0

This release fixes warnings when compiled with Elixir 1.15. It removes support
for Elixir 1.9.

## v1.0.0

This release has no changes except for the version number.

## v0.2.2

* New features
  * Add `:mode` option for setting socket file permissions. Thanks to Ed
    Wildgoose for this feature.

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
