mm_tool, a multimedia tool
==========================
[![Gem Version](https://badge.fury.io/rb/mm_tool_.svg)](https://badge.fury.io/rb/mm_tool_)


# About

Handles lots of media files with ffpmeg as a batch. Useful for cleaning, consolidating,
remuxing, and re-encoding media libraries.

# Installation

`gem install mm_tool` should do the trick.


# Change log

- 0.1.0

  - Initial release.

- 0.1.1

  - Fix to gemspec.

- 0.1.2

  - `--ignore-titles` is fixed.
  - Partially resolved the quality is interesting thing, but it's not a complete fix.
  - Fixed metadata for dropped streams.
  - Fix yaml wrapping.
  - Updated Gemfile dependencies.
  - Updated gemspec to not include certain bin files, which aren't needed and cause incompatibilities with other gems using same scaffold.
  - Updated readme.
  - Support multiple stream metadata changes.
  - Ensure we don't update metadata for streams we are dropping.

- 0.1.3

  - Natural sort order for directories with numbers, e.g., Season 1, … Season 19, Season 20.

- 0.1.4

  - Hot fix.
