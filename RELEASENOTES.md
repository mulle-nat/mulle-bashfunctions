## 6.4.0

feat: improve shell compatibility and error handling

* Enhance hostname detection and fallbacks
  - Add multiple hostname detection methods
  - Improve fallback chain with /etc/hostname support
  - Add nautilus as final fallback hostname
  - Fix hostname handling for various Unix systems

* Improve color and logging functionality
  - Add color deinitialization support
  - Add logging trap uninstallation
  - Fix color handling for dumb terminals
  - Make `NO_COLOR` handling more consistent

* Enhance technical flags and options
  - Rename --clear-flags to --mulle-clear-flags
  - Add --mulle-no-color and --mulle-no-colors flags
  - Add --mulle-no-error and --mulle-no-errors flags
  - Improve technical flags documentation

* Add filesystem improvements
  - Add `timestamp_now` function
  - Improve `file_devicenumber` for BSD systems
  - Add better logging for directory operations
  - Make directory listing more verbose in debug mode

* CMake improvements
  - Use `CMAKE_CURRENT_SOURCE_DIR` instead of `PROJECT_SOURCE_DIR`
  - Add explicit project version (6.4.0)
  - Add LANGUAGES NONE to project declaration


## 6.3.0

* added new command to keep mulle-sde out of the README picture


### 6.2.4

* add usage to README.md (and improve some text at the same time)

### 6.2.3

* fix `MULLE_BASH_EXE_SHELL` not being honored (any more ?)

### 6.2.2

* Various small improvements

### 6.2.1

* pass through -lx* flags

## 6.2.0

* new commands eval and r-eval to quickly test a function without having to create a mulle-bashfunctions script
* new commnads embed-booter and extract-booter to just add zsh/bash booting functionality to anotherwise non mulle-bashfunctions script
* somewhat improved tracing speed
* new function `r_smart_file_downcase_identifier` for C header shields for example e.g.  #ifndef `foo_h__`
* bugfix for termux (android)
* improved mulle-bashfunctions embedding (and update/removal) to create standalone scripts that don't need mulle-bashfunctions installed
* fix `r_extensionless_filename`
* add --silent-but-warn flag as a `MULLE_FLAG_LOG_TERSE` option
* add `shell_is_builtin_command` function


## 6.1.0

* somewhat improved tracing speed
* new function `r_smart_file_downcase_identifier` for C header shields for example e.g.  #ifndef `foo_h__`
* bugfix for termux (android)
* improved mulle-bashfunctions embedding (and update/removal) to create standalone scripts that don't need mulle-bashfunctions installed
* fix `r_extensionless_filename`
* add --silent-but-warn flag as a `MULLE_FLAG_LOG_TERSE` option
* add `shell_is_builtin_command` function


# 6.0.0

* added shell_is_variable_defined function
* added sort functions r_qsort and r_mergesort also adds global variables ascending and descending!
* error messages can be now suppressed with --no-errors, which can make nicer looking tests for example
* added r_line_at_index function
* added r_split and r_betwixt for string splitting and joining
* fix endless symlinks resolver loops
* new function r_make_tmpname_in_dir_uuidgen, when you don't want to create the file beforehand
* new functions file_devicenumber and r_file_type. r_file_type is clumsy, but stat is unfortunately not usable in a cross-plarform manner to figure out the file type
* new URL escaping function r_url_escape_path and r_url_unescape_path
* r_remove_duplicate renamed to the more telling r_remove_duplicate_separators
* mulle-bashfunctions gained an **apropos** function to search for functions by keyword, sort of
use new README.md CMS
* added a **man** command to get the documentation for a mulle-bashfunctions function. The command tries to be a little fuzzy to be more helpful
* have a fallback base64 encoder/decoder in case base64 is not installed
* use a custom uuidgen instead of an external one, therefore getting rid of that dependency
* fix script installer
* various fixes for obscure platforms like dragonfly, android, solaris
* detect android as separate platform
* detect msys2 as mingw for now



### 5.0.3

* fix installer for (gasp) solaris

### 5.0.2

* Various small improvements

# 5.0.0

* BREAKING change `_parallel` functions to `__parallel`
* `very_short_sleep` can take a microsecond parameter now
* `log_entry` now truncates argument output for readability
* `dir_list_files` can be set to list symlinks only
* mulle-bashfunctions are started now with `'! /usr/bin/env/mulle-bash`
* removed unused functions like concat `(r_concat` stays)
* added self-documenting functionality to mulle-bashfunctions


### 4.1.1

* add `r_de_camel_case_upcase_identifier` back for backwards compatibility
* fix `_remove_file_if_present` ignoring `MULLE_FLAG_EXEKUTOR_DRY_RUN`

## 4.1.0

* renamed `r_de_camel_case_upcase_identifier` to `r_smart_upcase_identifier` because it does something slightly different now


# 4.0.0

* option -T is -lT now
* mulle-bashfunctions-env is now mulle-bashfunctions, which makes the `include_library` code much simpler
* `include_library` is now just include
* changed include guards to be more C like, enabling double inclusion of mulle-bashfunctions in various forms
* added mulle-boot so the startup code for zsh/bash detection can be more compact
* added .foreachline et.al aliases. This neccessitates moving the mulle-bashfunctions init to the top of file file **HUGE CHANGE**
* ``expand_aliases`` is now defined by default, to enable .foreachline loops
* use new macros .foreachline .do .done statement
* new function `include_mulle_tool_library`
* add `r_extensionless_filename`
* added mulle-bashfunctions-embed so an embedded mulle-bashfunctions-embed.sh file can be easily updated
* add username command to mulle-bashfunctions-env
* add a file to make mulle-bashfunctions embeddable in another script with the cost of adding 80k of script code
* provide `MULLE_USERNAME` to shell scripts
* `MULLE_EXEKUTOR_STRACKTRACE_RVAL` to trigger stacktrace on return value changed from 2 to 18
* `r_semicolon_concat` does not remove trailing stray ';' anymore for CSV benefit
* moved ``log_grep_warning_error`` back to tools
* fix ``shell_disable_pipefail``
* fix parallel for MacOS monterey
* avoid error if etc folder is missing
* avoid duplicate output of commandline in tee-logger routines
* rename `assert_sane_name` to `r_assert_sane_name`
* new functions `r_get_last_line` and `r_remove_last_line`
* now uses "almagamated" files for faster startup
* changed the way the `-t` flag is handled, you now need to query either ``options_setup_trace`` or ``_options_mini_main``
* mulle-bashfunctions is now **compatible with zsh**
* **BREAKING** removed a lot of unused functions, specifically those with a `r_` counterpart. maybe the only ones left are ``r_physicalpath/physicalpath`.`
* added `mulle-compatiblity.sh` as bash/zsh glue for shell differences
* **BREAKING** extglob is not set/unset on demand anymore. All shell scripts are expected to run with **extglob enabled**
* mulle-bashfunctions now has precompiled headers, that improve startup time

## 3.4.0

* make remaining static log strings configurable
* fix accidental clobber in `inplace_sed` if sed failed
* new function `dirs_contain_same_files`
* new debug flags -lX -lS -lD, you can specify the debug depth now with -lDDD (3) for example, which means the flag affects the current command and those called nested twice
* added logging tee exekutor functions from mulle-make for use in build scripts
* Avoid prompt in `remove_file_if_present`
* Added `r_remove_line_once` function
* Added `r_url_remove_file_compression_extension` function
* `r_expanded_string` is now a proper interpreter and not just an eval for safety
* added `r_unescaped_doublequotes` and `r_lines_in_range`
* New URL parser "mulle-url.sh".

## 3.3.0

* r_resolve_all_path_symlinks added


### 3.2.1

* use sysctl for loadavg on freebsd/darwin

## 3.2.0

* added `remove_duplicate_lines` functions
* changed/fixed parameter order in `merge_line_into_file` now line,file
* keep `exekutor_print` output down to 240 characters
* added `logging_tee_eval_exekutor` from mulle-make
* upped cmake requirement ot 3.13


### 3.1.1

* no color if TERM is dumb + one obvious bug fix in `merge_line_into_file`

## 3.1.0

* added `r_expanded_string` to do eval printf -v a bit more safely


### 3.0.1

* remove unused `add_cmake_path` and `add_cmake_path_if_exists`
* added `file_is_binary` to file functions
* the `logging_tee_eval_exekutor` has moved to mulle-make as it is only used there
* lost the init command, this is now handled by `mulle-sde add`, consequently had to up the version to 3
* `_init` now should call main via `call_with_flags "main"` to enable insertion of FLAGS via environment
* use ``NO_COLOR`` instead of ``MULLE_NO_COLOR`` since its a standardization attempt i can deal with

# 3.0.0

* added `file_is_binary` to file functions
* the `logging_tee_eval_exekutor` has moved to mulle-make as it is only used there
* lost the init command, this is now handled by `mulle-sde add`, consequently had to up the version to 3
* `_init` now should call main via `call_with_flags "main"` to enable insertion of FLAGS via environment
* use `NO_COLOR` instead of `MULLE_NO_COLOR` since its a standardization attempt i can deal with


### 2.0.2

* symlink resolver fix

### 2.0.1

* fix wrong caseconversion

# 2.0.0

* version 2
* remove `r_prepend_path_if_relative`
* remove some old unused functions for version 2
* standardize on `r_dirname` and `r_basename` and remove all the other variations
* redo mulle-init to use RVAL functions
* fix some bugs found by shellcheck


## 1.12.0

* mulle-bashfunctions gains an init command for quick script setup


## 1.11.0

* `find_item` added
* `r_basename` and `r_dirname` supplant `r_basename` and `r_dirname`
* improved the old array code with less backticks
* improved quoting code
* added `r_available_core_count` with heuristics
* added `make::common::log_grep_warning_error` for mulle-make
* exekutor routines now set `MULLE_EXEKUTOR_RVAL` for status
* fix escaping but in `de_camel_case`
* add `r_remove_lin,`  `r_add_unique_line` , `r_reverse_lines`
* change `filepath_concat` to respect trailing / if part of filename
* use $'\n' instead of literal linefeed
* removed unused function `write_protect_directory`


### 1.10.4

* `path_extension` returns empty on no path extension now

### 1.10.3

* add some missing files

### 1.10.2

* improved exekutor output with nicer quoting
* `MULLE_HOSTNAME` is prefixed with `'_'` if the first character is '.'
* add -t- and -l- option to negate debug flags
* renamed `reval_exekutor` to `eval_rexekutor`

### 1.10.1

* `MULLE_HOSTNAME` is prefixed with `'_'` if the first character is '.'
* add -t- and -l- option to negate debug flags
* renamed `reval_exekutor` to `eval_rexekutor`

## 1.10.0

* add -t- and -l- option to negate debug flags
* renamed `reval_exekutor` to `eval_rexekutor`


### 1.9.1

* fix installer

## 1.9.0

* support for parallel execution of commands
* moved some unused code to mulle-legacy.sh
* tmpfile support with RVAL interface
* version support with RVAL interface


## 1.8.0

* Various small improvements


## 1.7.0

* add `redirect_eval_exekutor`
* `inplace_sed` moved to mulle-file.sh to fix problems on freebsd

### 1.6.3

* fixes for mingw
* fix hostname for mingw

### 1.6.2

* fix hostname for mingw

### 1.6.1

* small cleanups

## 1.6.0

* add `MULLE_USER_PWD` and mulle-case.sh


### 1.5.7

* fix installer rename in brew formula

### 1.5.6

* add bash and uuidgen dependencies for debian

### 1.5.5

* fix README.md

### 1.5.4

* rename install to installer, because of name conflict

### 1.5.3

* fix README.md some more

### 1.5.2

* fix README.md

### 1.5.1

* improve README, rename install.sh to install

## 1.5.0

* add `escaped_singlequotes,` add `MULLE_HOSTNAME`


## 1.4.0

* add escaping function and `sed_inplace` replace
* fix display bugs


### 1.3.2

* less confusing pid logging in exekutors
* don't use gratuitous subshell in eval exekutors if they can be avoided

### 1.3.1

* use MULLE_UNAME instead of UNAME in the future

## 1.3.0

* improve startup time greatly
* avoid globbing problems in for loops
* fast_dirname and basename -- added


### 1.2.3

* make minimal loading possible, useful for many scripts
* fix bugs in versioning checks

### 1.2.2

* fix bad and superflous mktemp use

### 1.2.1

* fix for filepath concat

## 1.1.0

* improved concat
* remove snip, which is too specialized and was buggy
* add path_extension


# 1.0.0

* Initial spin-off from mulle-bootstrap. Heavily under-documented
