# mulle-bashfunctions Library Documentation for AI
<!-- Keywords: shell, bash, zsh, scripting, portability, utilities, functions -->

## 1. Introduction & Purpose

mulle-bashfunctions is a comprehensive shell function library compatible with bash v3.2+ and zsh 5+. It provides a rich set of portable shell functions for developing feature-rich scripts that work consistently across multiple Unix-like platforms including Debian, FreeBSD, macOS, Manjaro, MinGW, NetBSD, OpenBSD, Solaris, and Ubuntu.

The library solves the problem of shell script portability and reduces boilerplate code by providing standardized utilities for common operations like string manipulation, file management, path handling, logging, execution control, and parallel processing. It abstracts away shell-specific differences between bash and zsh, allowing developers to write once and run everywhere.

Key features include:
- **Portability**: Seamless compatibility across bash 3.2+ and zsh 5+
- **Return value convention**: Functions prefixed with `r_` return values in the global `RVAL` variable for efficiency
- **Zero-cost logging**: Logging macros that can be eliminated when not needed
- **Comprehensive utilities**: String manipulation, file operations, path handling, URL parsing, version management, parallel execution, and more
- **Shell abstraction**: Compatibility layer that handles bash/zsh differences transparently
- **Embeddable scripts**: Scripts can be made standalone without requiring library installation
- **Self-documenting**: Built-in documentation accessible via `mulle-bashfunctions man <function>`

This is a foundational library used by many mulle-sde tools and projects.

## 2. Key Concepts & Design Philosophy

### RVAL Convention
The most distinctive design pattern is the use of the global `RVAL` variable for return values. Functions that return values via `RVAL` are prefixed with `r_` (or `_r_` for internal functions). This avoids the overhead of command substitution and subshells, making the code significantly faster. The `RVAL` value can be clobbered by any function call, so it must be used or saved immediately.

### Shell Compatibility Layer
The `mulle-compatibility.sh` module provides functions to handle differences between bash and zsh transparently. When run under zsh, the library automatically sets `sh_word_split`, `POSIX_ARGZERO`, and `GLOB_SUBST` options. The library requires `pipefail` and `extglob` (or equivalent) to be enabled and uses `expand_aliases` for macro support.

### Zero-Cost Abstractions
Logging functions have both function (`_log_*`) and alias (`log_*`) forms. The alias form can be eliminated by the shell if the log level doesn't require output, avoiding parameter expansion. For example, `log_verbose "PWD=$(pwd)"` won't execute `pwd` if verbose logging is disabled, while `_log_verbose` would still execute it.

### Data Structure Patterns

mulle-bashfunctions uses two distinct string-based patterns instead of native bash arrays:

**Arrays (newline-separated strings)**: Multi-line strings where each line is an element. Used for ordered collections that may contain any characters except newlines. Functions working with arrays are prefixed with `line` (e.g., `r_add_line`, `r_remove_line`, `find_line`).

```bash
# Array example (newline-separated)
array="foo
bar
baz"
```

**Lists (delimiter-separated strings)**: Single-line strings with items separated by a delimiter (`:`, `,`, `;`, `|`, etc.). Used for simple collections like PATH variables or tags. Functions working with lists use `concat` and `remove` with separator-specific variants (e.g., `r_colon_concat`, `r_comma_remove`).

```bash
# List examples (single-line with separators)
path="foo:bar:baz"           # colon-separated
tags="draft,important,todo"  # comma-separated
```

Both patterns provide portability across bash and zsh, work efficiently with the `RVAL` convention, and avoid the complexity of native array syntax. The `.foreachline` macro provides clean iteration for arrays.

### Execution Control
The `exekutor` pattern provides consistent logging and dry-run support for external command execution. Commands can be logged before execution, and dry-run mode (`-n` flag) prevents actual execution while showing what would run.

### Runtime Environment
- `pipefail` is set and expected
- `extglob` (bash) or `kshglob`/`bareglobqual` (zsh) is required
- `expand_aliases` is required for macro support
- `-u` (unset variable check) should work
- `-e` (exit on error) will NOT work - explicit error checking is required
- Glob settings remain at defaults

### Global Variables
Key global variables are prefixed with `MULLE_`:
- `MULLE_EXECUTABLE`: Path to the current script
- `MULLE_EXECUTABLE_NAME`: Script basename
- `MULLE_USER_PWD`: Original working directory when script started
- `MULLE_UNAME`: Standardized platform identifier
- `MULLE_BASHGLOBAL_SH`, `MULLE_*_SH`: Inclusion guards
- Various `MULLE_FLAG_*` and `MULLE_LOG_*` variables for configuration

## 3. Core API & Data Structures

### 3.1. `mulle-bashglobal.sh` (Core Initialization)

This is the foundation that must be included before any other module. It sets up the runtime environment and defines global variables.

**Key Globals:**
- `MULLE_BASHGLOBAL_SH`: Inclusion guard
- `DEFAULT_IFS`: Original IFS value
- `MULLE_EXECUTABLE`, `MULLE_EXECUTABLE_NAME`, `MULLE_EXECUTABLE_PWD`, `MULLE_EXECUTABLE_PID`: Script identity
- `MULLE_USER_PWD`: Original PWD for relative path display
- `MULLE_UNAME`: Platform identifier (darwin, linux, freebsd, mingw, sunos, etc.)
- `MULLE_EXECUTABLE_FAIL_PREFIX`: Prefix for error messages

**Key Functions:**
- Automatically sets zsh compatibility options
- Determines platform via `uname`
- No public functions - this is initialization only

### 3.2. `mulle-compatibility.sh` (Shell Abstraction)

Provides functions to control shell behavior consistently across bash and zsh.

**Pipefail Control:**
- `shell_enable_pipefail()`: Enable pipefail mode
- `shell_disable_pipefail()`: Disable pipefail mode
- `shell_is_pipefail_enabled()`: Check if enabled (returns 0 if yes)

**Extended Globbing:**
- `shell_enable_extglob()`: Enable extended glob patterns (sets `extglob` for bash, `kshglob`/`bareglobqual` for zsh)
- `shell_disable_extglob()`: Disable extended globbing
- `shell_is_extglob_enabled()`: Check if enabled

**Nullglob Control:**
- `shell_enable_nullglob()`: Make globs expand to nothing if no match
- `shell_disable_nullglob()`: Restore normal glob behavior
- `shell_is_nullglob_enabled()`: Check if enabled

**Alias Expansion:**
- `shell_enable_expand_aliases()`: Enable alias expansion (required for `.foreachline` macros)
- `shell_disable_expand_aliases()`: Disable alias expansion
- `shell_is_expand_aliases_enabled()`: Check if enabled

**Function Existence:**
- `shell_is_function <name>`: Check if function is defined

### 3.3. `mulle-logging.sh` (Logging and Error Handling)

Provides colorized logging functions with multiple severity levels. Colorization respects the `NO_COLOR` environment variable.

**Log Levels (from most to least severe):**
- `_log_fail()` / `fail()`: Fatal error, exits immediately
- `_log_error()` / `log_error()`: Error message (can be squelched with `MULLE_FLAG_LOG_ERROR=NO`)
- `_log_warning()` / `log_warning()`: Warning message
- `_log_info()` / `log_info()`: Informational message
- `_log_verbose()` / `log_verbose()`: Verbose message (shown with `-v`)
- `_log_fluff()` / `log_fluff()`: Very verbose message (shown with `-vv`)
- `_log_debug()` / `log_debug()`: Debug message (shown with `-vvv`)
- `_log_trace()` / `log_trace()`: Trace message (shown with trace mode)
- `_log_entry()` / `log_entry()`: Function entry trace (shown with `-te`)

**Special Functions:**
- `_internal_fail()`: Internal consistency error
- `stacktrace()`: Print bash/zsh stack trace
- `log_printf()`: Low-level formatted output

**Configuration Globals:**
- `MULLE_FLAG_LOG_VERBOSE`: Set to 'YES' for verbose
- `MULLE_FLAG_LOG_FLUFF`: Set to 'YES' for very verbose
- `MULLE_FLAG_LOG_DEBUG`: Set to 'YES' for debug
- `MULLE_FLAG_LOG_ERROR`: Set to 'NO' to suppress errors
- `MULLE_EXEKUTOR_LOG_DEVICE`: Redirect log output to a file
- `NO_COLOR`: Set to disable colorization

**Best Practice:** Use the alias form (`log_*`) in normal code for zero-cost logging. Use the function form (`_log_*`) only when using line continuations or complex parameter expansion.

### 3.4. `mulle-exekutor.sh` (Command Execution)

Controls execution of external commands with logging and dry-run support.

**Core Execution Functions:**
- `exekutor <cmd> [args...]`: Execute command with logging, respects dry-run mode (skips execution when `-n` flag is set). Use for commands that modify state.
  ```bash
  exekutor touch file           # Skipped during dry-run
  exekutor rm -f old_file       # Skipped during dry-run
  exekutor mkdir -p directory   # Skipped during dry-run
  ```

- `rexekutor <cmd> [args...]`: Execute "read-only" command with logging, runs even during dry-run mode because it's deemed harmless. Use for commands that only read data.
  ```bash
  rexekutor grep foo file       # Runs even during dry-run
  rexekutor ls -la directory    # Runs even during dry-run
  rexekutor cat config.txt      # Runs even during dry-run
  ```

- `eval_exekutor <cmd_string>`: Execute string with eval and logging (respects dry-run mode)
- `eval_rexekutor <cmd_string>`: Eval version of rexekutor (runs during dry-run)
- `logging_eval_exekutor <cmd_string>`: Like eval_exekutor with more verbose logging

**Tee Execution (capture output while logging):**
- `exekutor_tee <file> <cmd> [args...]`: Execute and tee to file
- `eval_exekutor_tee <file> <cmd_string>`: Eval and tee to file

**Redirection Variants:**
- `redirect_eval_exekutor <target> <cmd_string>`: Redirect output to target
- `redirect_exekutor <target> <cmd> [args...]`: Redirect execution to target

**Printing (show command without executing):**
- `exekutor_print <cmd> [args...]`: Print command as it would be executed
- `eval_exekutor_print <cmd_string>`: Print eval command

**Configuration:**
- `MULLE_FLAG_EXEKUTOR_DRY_RUN=YES`: Enable dry-run mode (show commands but don't execute)
- `MULLE_FLAG_LOG_EXEKUTOR=YES`: Enable execution logging

### 3.5. `mulle-options.sh` (Command-Line Parsing)

Handles standard mulle-bashfunctions command-line options for verbosity, tracing, and technical flags.

**Main Functions:**
- `options_technical_flags <flag>`: Parse and handle technical flags (-v, -n, -s, -ld, -t, etc.). Returns 0 if flag was handled.
- `options_setup_trace <mode>`: Setup tracing based on mode. Returns 0 if shell tracing should be enabled.
- `options_mini_main <cmd> [args...]`: Minimal main function for simple scripts

**Standard Flags Handled:**
- `-n`: Dry run mode
- `-s`: Silent mode
- `-v`, `-vv`, `-vvv`: Increasing verbosity levels
- `-ld`: Log directory operations
- `-le`: Log exekutor commands
- `-lx`: Log external commands
- `-t`, `-te`, `-td`: Trace variants

**Global for Forwarding:**
- `MULLE_TECHNICAL_FLAGS`: Contains all technical flags to forward to child scripts

### 3.6. `mulle-string.sh` (String Manipulation)

Extensive string manipulation utilities organized by category.

#### Conversion Functions:
- `r_trim_whitespace <string>`: Remove leading/trailing whitespace
- `r_uppercase <string>`: Convert to uppercase
- `r_lowercase <string>`: Convert to lowercase  
- `r_capitalize <string>`: Capitalize first letter
- `r_upper_firstchar <string>`: Uppercase first character only
- `r_identifier <string>`: Convert to valid identifier (letters, digits, underscore)
- `r_extended_identifier <string>`: Allow dots and dashes
- `r_smart_downcase_identifier <string>`: Smart camelCase to snake_case conversion
- `r_smart_upcase_identifier <string>`: snake_case to camelCase conversion

#### List Operations (single-line, delimiter-separated):
- `r_concat <string1> <string2> [sep]`: Concatenate with separator
- `r_concat_unique <list> <item> [sep]`: Add if not present
- `r_concat_if_missing <list> <item> [sep]`: Add if missing
- `r_colon_concat <list> <item>`: Colon-separated concatenation
- `r_comma_concat <list> <item>`: Comma-separated concatenation
- `r_semicolon_concat <list> <item>`: Semicolon-separated concatenation
- `r_list_remove <list> <item> [sep]`: Remove item from separated list
- `r_colon_remove <list> <item>`: Remove from colon-separated list
- `r_comma_remove <list> <item>`: Remove from comma-separated list
- `find_item <list> <item> [sep]`: Find item in separated list

#### Array Operations (multi-line, newline-separated):
- `r_add_line <array> <line>`: Add line to newline-separated array
- `r_add_unique_line <array> <line>`: Add if not present
- `r_remove_line <array> <line>`: Remove first matching line
- `r_remove_line_once <array> <line>`: Remove first occurrence only
- `r_get_last_line <array>`: Get last line
- `r_line_at_index <array> <index>`: Get line at index
- `r_remove_last_line <array>`: Remove last line
- `r_count_lines <array>`: Count lines
- `r_reverse_lines <array>`: Reverse line order
- `remove_duplicate_lines <array>`: Remove duplicates (preserves order)
- `remove_duplicate_lines_stdin`: Remove duplicates from stdin
- `find_line <array> <pattern>`: Find line matching pattern (returns 0 if found)

#### Conversion:
- `r_split <string> <sep>`: Split string into bash/zsh array (returns native array in RVAL)
- Convert lists to arrays: `array="${list//:/$'\n'}"` (replace separator with newline)

#### General String Operations:
- `r_append <string> <suffix>`: Simple append
- `r_slash_concat <path1> <path2>`: Slash-separated concatenation
- `r_betwixt <string> <start> <end>`: Extract text between start and end markers
- `r_remove_duplicate_separators_lines <array>`: Collapse multiple newlines
- `is_yes <value>`: Check if value represents yes/true/on/1

#### Escaping Functions:
- `r_escaped_grep_pattern <string>`: Escape for grep pattern
- `r_escaped_sed_pattern <string>`: Escape for sed pattern
- `r_escaped_sed_replacement <string>`: Escape for sed replacement
- `r_escaped_spaces <string>`: Escape spaces with backslash
- `r_escaped_backslashes <string>`: Escape backslashes
- `r_escaped_singlequotes <string>`: Escape single quotes
- `r_escaped_doublequotes <string>`: Escape double quotes
- `r_unescaped_doublequotes <string>`: Unescape double quotes
- `r_escaped_shell_string <string>`: Escape for shell
- `r_escaped_json <string>`: Escape for JSON
- `r_escaped_html <string>`: Escape for HTML

#### Hashing:
- `r_sha256 <string>`: Calculate SHA256 hash of string
- `r_fast_hash <string>`: Fast non-cryptographic hash
- `r_mulle_hostname_hash <hostname>`: Hash hostname

### 3.7. `mulle-path.sh` (Path Manipulation)

Path operations that do NOT touch the filesystem.

#### Path Cleaning:
- `r_filepath_cleaned <path>`: Remove excess `/` and `./` components
- `r_simplified_path <path>`: Resolve `..` components without filesystem access
- `r_remove_ugly <path>`: Remove leading `./` for prettier output

#### Path Concatenation:
- `r_filepath_concat <comp1> <comp2> ...`: Concatenate path components with `/`
- `r_filepath_concat_if_relative <base> <path>`: Concat if path is relative
- `r_relative_path_between <from> <to>`: Calculate relative path

#### Path Components:
- `r_basename <path>`: Get filename component
- `r_dirname <path>`: Get directory component  
- `r_extensionless_basename <path>`: Basename without extension
- `r_extensionless_filename <path>`: Filename without extension
- `r_path_extension <path>`: Get file extension
- `r_expanded_string <string>`: Expand tilde and environment variables

#### Path Analysis:
- `is_absolutepath <path>`: Check if path is absolute
- `is_relativepath <path>`: Check if path is relative
- `r_determine_user_home_dir <user>`: Get home directory for user

### 3.8. `mulle-file.sh` (File Operations)

File and directory operations that DO interact with the filesystem.

#### Directory Creation:
- `mkdir_if_missing <dir>`: Create directory if not present, fail on error
- `r_mkdir_parent_if_missing <file>`: Ensure parent directory exists
- `rmdir_safer <dir>`: Remove directory with safety checks
- `rmdir_if_empty <dir>`: Remove only if empty

#### Directory Inspection:
- `dir_is_empty <dir>`: Check if directory is empty (returns 0 if yes)
- `dir_has_files <dir>`: Check if directory contains files
- `dir_list_files <dir>`: List files in directory
- `dirs_contain_same_files <dir1> <dir2>`: Compare directory contents

#### File Creation/Modification:
- `create_file_if_missing <file> [contents]`: Create file if not present
- `merge_line_into_file <line> <file>`: Add line to file if not present
- `remove_file_if_present <file>`: Remove file, no error if missing
- `inplace_sed <pattern> <file>`: Modify file with sed in-place

#### Symlink Operations:
- `create_symlink <target> <linkname>`: Create symlink with safety checks
- `r_resolve_symlinks <path>`: Follow all symlinks
- `r_resolve_all_path_symlinks <path>`: Resolve symlinks in all path components

#### Path Resolution:
- `r_canonicalize_path <path>`: Get canonical absolute path
- `r_physicalpath <path>`: Resolve all symlinks to physical path
- `r_realpath <path>`: Like realpath(3), resolves to physical path

#### File Information:
- `modification_timestamp <file>`: Get modification time as Unix timestamp
- `timestamp_now`: Get current Unix timestamp
- `file_devicenumber <file>`: Get device number for file
- `r_file_type <file>`: Get file type (file, directory, symlink, etc.)
- `file_size_in_bytes <file>`: Get file size
- `file_is_binary <file>`: Check if file is binary (returns 0 if yes)
- `lso <file>`: List single file with long format

#### Temporary Files:
- `r_make_tmp`: Create temp file in system temp directory
- `r_make_tmp_file`: Create temp file with more control
- `r_make_tmp_directory`: Create temp directory
- `r_uuidgen`: Generate UUID

### 3.9. `mulle-array.sh` (Array Operations)

Arrays represented as newline-separated strings.

#### Basic Operations:
- `r_add_line_lf <array> <line>`: Add line (linefeed-separated)
- `r_get_line_at_index <array> <index>`: Get line at index
- `r_insert_line_at_index <array> <index> <line>`: Insert line
- `r_set_line_at_index <array> <index> <line>`: Replace line at index

#### Associative Array Simulation:
- `r_assoc_array_set <array> <key> <value>`: Set key-value pair
- `r_assoc_array_get <array> <key>`: Get value for key
- `r_assoc_array_all_keys <array>`: List all keys
- `r_assoc_array_all_values <array>`: List all values
- `r_assoc_array_delete <array> <key>`: Delete key-value pair

#### Iteration Macros:
- `.foreachline var in array .do ... .done`: Iterate over lines
- `.foreachitem var in list .do ... .done`: Iterate over items (with separator)
- `.foreachfile var in glob .do ... .done`: Iterate over glob matches

**Note:** These macros require `expand_aliases` to be enabled.

### 3.10. `mulle-case.sh` (Case Conversion)

camelCase and snake_case conversions.

**Functions:**
- `r_smart_file_upcase_identifier <filename>`: Convert filename to UpperCamelCase
- `r_smart_file_downcase_identifier <filename>`: Convert filename to snake_case
- `r_smart_upcase_identifier <string>`: snake_case to camelCase
- `r_smart_downcase_identifier <string>`: camelCase to snake_case
- `r_tweaked_de_camel_case <string>`: Advanced de-camelization with special rules

**Special Handling:**
- Handles acronyms intelligently (e.g., "XMLParser" → "xml_parser")
- Preserves "Objc" as special case (ObjC → Objc)
- Handles consecutive capitals correctly

### 3.11. `mulle-parallel.sh` (Parallel Execution)

Controlled parallel execution of background processes.

#### Simple Parallel Execution:
- `parallel_execute <args_array> <cmd> [cmd_args...]`: Execute command in parallel for each argument

#### Advanced Control (use together):
- `__parallel_begin`: Initialize parallel execution context (must call first)
- `__parallel_execute <cmd> [args...]`: Queue command for parallel execution
- `__parallel_end`: Wait for all parallel commands to complete

**Context Variables (initialized by `__parallel_begin`):**
- `_parallel_statusfile`: Temp file tracking job status
- `_parallel_maxjobs`: Maximum concurrent jobs (defaults to number of cores)
- `_parallel_jobs`: Current job count
- `_parallel_fails`: Failure count

**Configuration:**
- Automatically limits concurrent jobs to available CPU cores
- Monitors system load to avoid swamping the machine
- Collects exit statuses from all background processes
- Returns non-zero if any job failed

#### Sleep Utilities:
- `very_short_sleep <microseconds>`: Microsecond sleep for polling
- `short_sleep <seconds>`: Short sleep with platform compatibility

### 3.12. `mulle-url.sh` (URL Parsing)

Parse and manipulate URLs.

#### Encoding:
- `r_url_encode <url>`: Encode unsafe characters as %XX
- `r_url_path_encode <url>`: Encode but preserve forward slashes
- `r_url_decode <url>`: Decode %XX sequences

#### URL Parsing (for URLs in format `[scheme:][//domain][/path][?query][#fragment]`):
- `r_url_get_scheme <url>`: Extract scheme (e.g., "https")
- `r_url_get_domain <url>`: Extract domain
- `r_url_get_path <url>`: Extract path component
- `r_url_get_query <url>`: Extract query string
- `r_url_get_fragment <url>`: Extract fragment
- `r_url_remove_scheme <url>`: Remove scheme prefix
- `r_url_remove_query <url>`: Remove query string
- `r_url_remove_fragment <url>`: Remove fragment

#### Specialized Parsers:
- `r_url_parse_file <file_url>`: Parse file:// URLs
- `r_url_parse_github <github_url>`: Parse GitHub URLs into components

### 3.13. `mulle-version.sh` (Version Management)

Semantic version handling (major.minor.patch format).

#### Version Parsing:
- `r_get_version_major <version>`: Extract major component
- `r_get_version_minor <version>`: Extract minor component
- `r_get_version_patch <version>`: Extract patch component

#### Version Arithmetic:
- `version_to_32bit_int <version>`: Convert to integer for comparison ((major << 20) | (minor << 8) | patch)
- `r_32bit_int_to_version <int>`: Convert integer back to version string
- `r_increment_version_patch <version>`: Increment patch number
- `r_increment_version_minor <version>`: Increment minor, reset patch
- `r_increment_version_major <version>`: Increment major, reset minor and patch

#### Version Comparison:
- `version_is_greater <version1> <version2>`: Returns 0 if version1 > version2
- `version_is_greater_or_equal <version1> <version2>`: Returns 0 if version1 >= version2
- `version_is_less <version1> <version2>`: Returns 0 if version1 < version2

### 3.14. `mulle-etc.sh` (Etc/Share Management)

Manage `.mulle/etc` and `.mulle/share` folder shadowing pattern.

**Concept:** The `share` directory contains read-only template files that are upgraded. The `etc` directory contains user-editable copies. Unchanged files are symlinked from etc to share, allowing upgrades while preserving edits.

**Functions:**
- `etc_make_file_from_symlinked_file <file>`: Convert symlink to actual file for editing
- `etc_make_file_from_share_file <etc_file> <share_file>`: Copy share file to etc
- `etc_setup_from_share <etc_dir> <share_dir>`: Initialize etc from share

### 3.15. `mulle-base64.sh` (Base64 Encoding)

Pure shell base64 encoding implementation.

**Functions:**
- `r_mulle_base64_encode_string [width] <string>`: Encode string to base64
- `mulle_isbase64_char <char>`: Check if character is valid base64

**Note:** Primarily for systems without base64 utility. Width parameter controls line wrapping.

## 4. Performance Characteristics

### RVAL Pattern
- **O(1)** - Using RVAL for return values avoids subprocess overhead
- Significantly faster than `var=$(func)` command substitution which forks a subshell
- Essential for functions called in tight loops

### String Operations
- Most string operations are **O(n)** where n is string length
- Built using shell parameter expansion, avoiding external process calls
- Line iteration with `.foreachline` is **O(n)** for n lines
- `remove_duplicate_lines` is **O(n²)** but preserves order; use `sort -u` for **O(n log n)** if order doesn't matter

### File Operations
- File creation/deletion: **O(1)** filesystem operations
- `dir_is_empty`: **O(1)** - tests existence of first directory entry
- `dirs_contain_same_files`: **O(n)** for n files
- Symlink resolution: **O(d)** for d directory depth
- `r_canonicalize_path`: Involves filesystem access, relatively expensive

### Path Operations
- Pure string manipulation operations (cleaning, concatenation): **O(n)** for path length
- No filesystem access makes path operations very fast
- `r_relative_path_between`: **O(n)** for path component count

### Array Operations
- Access by index: **O(n)** - must iterate through newlines
- Insert/delete: **O(n)** - requires string rebuilding
- Associative array operations: **O(n)** - linear search through key-value pairs
- Native bash arrays would be faster but less portable

### Parallel Execution
- CPU-bound parallelism: Scales with available CPU cores (typically 4-32)
- Load monitoring prevents system swamping
- Small overhead from status file I/O

### Thread Safety
- **Not thread-safe** - Shell scripts use global variables extensively
- Parallel execution uses background processes (separate process spaces), not threads
- Each background process has isolated state

### Best Performance Practices
- Use RVAL functions instead of command substitution
- Call expensive functions once and cache results
- Use built-in string operations instead of external tools (sed, awk, cut)
- For large arrays, consider external tools (sort, uniq) instead of shell loops
- Use parallel execution for I/O-bound or CPU-intensive tasks

## 5. AI Usage Recommendations & Patterns

### Best Practices

#### Library Loading

Use `.include 'logging'` to load library `"${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-logging.sh"`
do not use direct loading code.


#### RVAL Usage
```bash
# Correct: Use RVAL immediately
r_filepath_concat "${dir}" "${file}"
fullpath="${RVAL}"

# Wrong: RVAL gets clobbered
r_filepath_concat "${dir}" "${file}"
r_basename "${file}"
# RVAL no longer contains fullpath!

# Correct: Chain calls properly
r_filepath_concat "${dir}" "${file}"
fullpath="${RVAL}"
r_basename "${file}"
filename="${RVAL}"
```

#### Logging Levels
- Use `fail` for fatal errors
- Use `log_error` for errors that should be visible
- Use `log_warning` for warnings
- Use `log_verbose` for optional details (-v flag)
- Use `log_fluff` for very detailed output (-vv flag)
- Use `log_debug` for debugging output (-vvv flag)

#### Command Execution
Always use `exekutor` instead of direct execution for consistency:

```bash
# Good: Respects dry-run, logs execution
exekutor touch "${tmpdir}"

# Bad: Direct execution
touch "${tmpdir}"
```

#### Error Checking
Always check return values explicitly (don't rely on -e):
```bash
# Good
if ! some_command
then
   fail "Command failed"
fi

# Also good with ||
some_command || fail "Command failed"
```

#### Array Iteration
Use `.foreachline` macro for clean code:
```bash
.foreachline item in ${array}
.do
   log_info "Processing: ${item}"
.done
```

#### Working with Lists
Lists are strings with items separated by delimiters (colon, comma, semicolon, etc.):

```bash
# Creating lists
list=""
r_colon_concat "${list}" "foo"
list="${RVAL}"
r_colon_concat "${list}" "bar"
list="${RVAL}"
r_colon_concat "${list}" "baz"
list="${RVAL}"
# list is now "foo:bar:baz"

# Finding items in lists
if find_item "${list}" "bar" ":"
then
   log_info "Found bar in list"
fi

# Removing items from lists
r_colon_remove "${list}" "bar"
list="${RVAL}"
# list is now "foo:baz"

# Working with different separators
# Colon-separated (PATH-style)
r_colon_concat "${path}" "/usr/local/bin"
r_colon_remove "${path}" "/usr/bin"

# Comma-separated
r_comma_concat "${tags}" "important"
r_comma_remove "${tags}" "draft"

# Custom separator
r_concat "${items}" "newitem" "|"
r_list_remove "${items}" "olditem" "|"

# Converting lists to arrays for iteration
# Use .foreachitem directly with the separator
.foreachitem item in ${list} ":"
.do
   log_info "Item: ${item}"
.done

# Or convert to newline-separated with parameter expansion
array="${list//:/$'\n'}"
.foreachline item in ${array}
.do
   log_info "Item: ${item}"
.done
```

### Common Pitfalls

#### Forgetting RVAL is Global
```bash
# Wrong: Second call clobbers RVAL from first call
r_filepath_concat "${dir}" "${file}"
r_basename "${file}"
fullpath="${RVAL}"  # This is the basename, not the full path!

# Correct: Save RVAL immediately after each call
r_filepath_concat "${dir}" "${file}"
fullpath="${RVAL}"
r_basename "${file}"
filename="${RVAL}"
```

#### Not Checking Inclusion Guards
```bash
# Wrong: Might load twice or in wrong order
. mulle-string.sh

# Correct: Let the library handle it
if [ -z "${MULLE_STRING_SH}" ]
then
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh"
fi
```

#### Using Command Substitution for RVAL Functions
```bash
# Wrong: Defeats the purpose of RVAL pattern
result=$(r_basename "${file}" && echo "${RVAL}")

# Correct: Use RVAL directly
r_basename "${file}"
result="${RVAL}"
```

#### Mixing -e with mulle-bashfunctions
```bash
# Wrong: -e is not supported
set -e
some_function || log_error "failed"  # -e will exit before log_error runs

# Correct: Always check explicitly
if ! some_function
then
   fail "Function failed"
fi
```
#### Forgetting zsh quirks

DO NOT USE `local <varname>` in loops.
DO NOT REUSE the same local variable name in the same function.
DO NOT use `${!varname}` use r_shell_indirect_expand


### Idiomatic Usage Patterns

#### Script Template

Use `mulle-bashfunctions new` to create a new script template. Do not
mess around trying to write it from scratch yourself.


#### Parallel Processing Pattern
```bash
process_files()
{
   local files="$1"
   
   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails
   
   __parallel_begin
   
   .foreachline file in ${files}
   .do
      __parallel_execute process_one_file "${file}"
   .done
   
   __parallel_end || fail "Processing failed"
}
```

#### Path Building Pattern
```bash
# Build complex paths safely
r_filepath_concat "${basedir}" "subdir"
r_filepath_concat "${RVAL}" "file.txt"
filepath="${RVAL}"

# Ensure parent exists
r_mkdir_parent_if_missing "${filepath}"
create_file_if_missing "${filepath}" "content"
```

## 6. Integration Examples

### Example 1: String Processing Script

```c
#! /usr/bin/env mulle-bash

[ "${TRACE}" = 'YES' -o "${PROCESS_IDENTIFIER_TRACE}" = 'YES' ] && set -x  && : "$0" "$@"

### >> START OF mulle-boot.sh >>
### << END OF mulle-boot.sh <<

#
# Versioning of this script
#
MULLE_EXECUTABLE_VERSION="0.0.1"


### >> START OF mulle-bashfunctions-embed.sh >>
### << END OF mulle-bashfunctions-embed.sh <<

print_flags()
{
   echo "   -f    : force operation"

   options_technical_flags_usage                 "         : "
}


usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} [options] <identifier> ...

   Convert camelCase identifiers to snake_case.

EOF
   exit 1
}

#
# Convert camelCase identifiers to snake_case
#
process_identifier()
{
   log_entry 'process_identifier' "$@"

   local input="$1"

   r_smart_downcase_identifier "${input}"
   output="${RVAL}"

   log_info "Converted: ${input} -> ${output}"
   printf "%s\n" "${output}"
}


main()
{
   #
   # simple option/flag handling
   #
   local OPTION_VALUE

   while [ $# -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -f|--force)
            MULLE_FLAG_MAGNUM_FORCE='YES'
         ;;

         -h*|--help|help)
            usage
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         -*)
            usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   if [ $# -eq 0 ]
   then
      fail "No identifiers provided"
   fi

   local identifier

   for identifier in "$@"
   do
      process_identifier "${identifier}"
   done
}

main "$@"
```



### Example 2: File Organization Tool

```c
#
# Organize files by extension into subdirectories
#
organize_files()
{
   log_entry 'organize_files' "$@"

   local srcdir="$1"
   local dstdir="$2"
   
   if [ ! -d "${srcdir}" ]
   then
      fail "Source directory '${srcdir}' does not exist"
   fi
   
   mkdir_if_missing "${dstdir}"
   
   local file
   local ext
   local category_dir
   
   .foreachpath file in "${srcdir}"/*
   .do
      if [ ! -f "${file}" ]
      then
         .continue
      fi
      
      r_basename "${file}"
      filename="${RVAL}"
      
      r_path_extension "${file}"
      ext="${RVAL}"
      
      if [ -z "${ext}" ]
      then
         ext="no-extension"
      fi
      
      r_filepath_concat "${dstdir}" "${ext}"
      category_dir="${RVAL}"
      
      mkdir_if_missing "${category_dir}"
      
      r_filepath_concat "${category_dir}" "${filename}"
      dstfile="${RVAL}"
      
      log_verbose "Moving: ${filename} -> ${ext}/"
      exekutor mv "${file}" "${dstfile}"
   .done
   
   log_info "Files organized in: ${dstdir}"
}
```

### Example 3: Parallel Processing with Error Handling

```c

#
# Process a single file (this runs in background)
#
process_file()
{
   log_entry 'process_file' "$@"

   local file="$1"
   local outdir="$2"
   
   r_basename "${file}"
   filename="${RVAL}"
   
   log_fluff "Processing: ${filename}"
   
   r_filepath_concat "${outdir}" "${filename}.processed"
   outfile="${RVAL}"
   
   if ! exekutor some-processing-command "${file}" "${outfile}"
   then
      log_error "Failed to process: ${filename}"
      return 1
   fi
   
   log_verbose "Completed: ${filename}"
   return 0
}

#
# Process all files in parallel
#
process_files_parallel()
{
   log_entry 'process_file' "$@"

   local srcdir="$1"
   local outdir="$2"
   
   include "mulle-parallel"

   mkdir_if_missing "${outdir}"
   
   local file
   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails
   
   __parallel_begin
   
   .foreachpath file in "${srcdir}"/*.txt
   .do
      __parallel_execute process_file "${file}" "${outdir}"
   .done
   
   if ! __parallel_end
   then
      fail "Some files failed to process"
   fi
   
   log_info "All files processed successfully"
}
```

### Example 4: URL Parsing and Version Comparison

```c
#
# Parse GitHub URL and extract version from tag
#
analyze_github_release()
{
   local url="$1"
   
   r_url_parse_github "${url}"
   github_info="${RVAL}"
   
   r_get_line_at_index "${github_info}" 0
   user="${RVAL}"
   
   r_get_line_at_index "${github_info}" 1
   repo="${RVAL}"
   
   r_get_line_at_index "${github_info}" 2
   tag="${RVAL}"
   
   log_info "Repository: ${user}/${repo}"
   log_info "Tag: ${tag}"
   
   # Extract version from tag (assume format vX.Y.Z)
   version="${tag#v}"
   
   r_get_version_major "${version}"
   major="${RVAL}"
   
   r_get_version_minor "${version}"
   minor="${RVAL}"
   
   r_get_version_patch "${version}"
   patch="${RVAL}"
   
   log_info "Version: ${major}.${minor}.${patch}"
   
   # Check if version is at least 2.0.0
   if version_is_greater_or_equal "${version}" "2.0.0"
   then
      log_info "Version is 2.0 or newer"
   else
      log_warning "Version is older than 2.0"
   fi
}
```

## 7. Dependencies

This library is self-contained and has no mulle-sde dependencies. It only requires:
- bash 3.2+ or zsh 5+
- Standard Unix utilities: sed, awk, grep, find, etc.
- Core shell built-ins and parameter expansion

Note: While mulle-bashfunctions is used by mulle-sde, it does not depend on mulle-sde. It is a foundational shell scripting library.
