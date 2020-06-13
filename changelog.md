# Changes

## 1.0.2

- Setting `percentage` to 100.0 (`real`) instead of 100 (`integer`) with AppleScript now correctly sets the indicator as done
- Fixed a bug that caused a newly created indicator to never time out and thus never showed a cancel button
- Rewrote `demo.applescript` and `demo_error.applescript` by encapsulating indicator communication in discrete functions with the benefit that the script will still run even if Progress is not installed. 

## 1.0.1

- First public release
