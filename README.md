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

- 0.1.5

  - Updated for Ruby 2.7 compatibility.

- 0.1.6

  - Make ffmpeg output less verbose.
  - Don't do "slow" video conversions.

- 0.1.7

  - Added `shell_commands` user default, so that we can suppress the printing of
    the shell commands, such as when summarizing the work already performed.

- 0.1.8

  - Fix single quoting.

- 0.1.9

  - Add different encoder support.

- 0.1.10

  - Fix underscore issue.


- 0.1.11

  - Add force (re-encode) option.

- 0.1.12

  - Fix preference, shorten string.

- 0.1.13

  - Put the name of the temporary file at the end of output, so we don't have to scroll all the way to the top
    to find out what it is.

  - Plant a flag when we've touched a file.

    - For whole file:
      - MM_TOOL_ENCODED=true|false       Set to true if any part of the file was transcoded.
      - MM_TOOL_WRITTEN=true|false       Set to true if the file was written by mm_tool, for example, possibly
                                         nothing was transcoded, but streams were dropped or added. If EVERY stream
                                         is copy ONLY, then we don't apply this.

    - For streams:
    - MM_TOOL_ENCODED_STREAM=true|false  Set to true if the stream is transcoded.
