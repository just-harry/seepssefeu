# seepssefeu

## Changelog

### Version 1.1.1

- A misuse of sed that caused the Shell bootstrap script to fail on macOS when pwsh could be found by `which` was fixed.

### Version 1.1.0

- Support was added for generating a Batch file, for Windows, that can detect if it's been run from within a zip-archive opened in Windows Explorer, and which can then copy itself to the local app-data folder so that the file extraction succeeds.
