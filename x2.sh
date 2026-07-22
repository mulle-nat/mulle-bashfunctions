#! /usr/bin/env mulle-bash



log_checker()
{
   log_entry "log_checker" "$@"

   local rval=0
   local option_repair='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         --repair)
            option_repair='YES'
         ;;

         -*)
            fail "Unknown log-checker option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   if [ $# -eq 0 ]
   then
      fail "Usage: mulle-bashfunctions log-checker [--repair] <file> ..."
   fi

   local filename

   for filename in "$@"
   do
      if [ ! -f "${filename}" ]
      then
         log_warning "${filename}: not found"
         continue
      fi

      local line
      local lineno=0
      local in_log=""
      local log_lineno=""
      local log_funcname=""

      while IFS= read -r line || [ -n "${line}" ]
      do
         lineno=$((lineno + 1))

         #
         # If we are tracking an open multiline (continuation or unclosed
         # quote) from a previous log_ line, check if it ends here.
         #
         if [ -n "${in_log}" ]
         then
            case "${in_log}" in
               continuation)
                  case "${line}" in
                     *\\)
                     ;;

                     *)
                        log_error "${filename}:${log_lineno}: \"${log_funcname}\" spans multiple lines (use _${log_funcname} instead)"
                        if [ "${option_repair}" = 'YES' ]
                        then
                           inplace_sed -e "${log_lineno}s/^\([[:space:]]*\)${log_funcname}/\1_${log_funcname}/" \
                                       -e "${log_lineno}s/\([^_a-zA-Z0-9]\)${log_funcname}/\1_${log_funcname}/" \
                                       "${filename}"
                           log_info "repaired ${filename}:${log_lineno}"
                        fi
                        rval=1
                        in_log=""
                     ;;
                  esac
               ;;

               openquote)
                  # look for closing double quote (not escaped)
                  case "${line}" in
                     *'"'*)
                        log_error "${filename}:${log_lineno}: \"${log_funcname}\" has multiline string argument (use _${log_funcname} instead)"
                        if [ "${option_repair}" = 'YES' ]
                        then
                           inplace_sed -e "${log_lineno}s/^\([[:space:]]*\)${log_funcname}/\1_${log_funcname}/" \
                                       -e "${log_lineno}s/\([^_a-zA-Z0-9]\)${log_funcname}/\1_${log_funcname}/" \
                                       "${filename}"
                           log_info "repaired ${filename}:${log_lineno}"
                        fi
                        rval=1
                        in_log=""
                     ;;
                  esac
               ;;
            esac
            continue
         fi

         #
         # Check if line contains a log_ alias call (not _log_).
         # The call can appear after && or || or ; etc., so we use
         # a regex-like grep approach rather than prefix matching.
         #
         # We use sed to extract the log_ function name if present.
         # Match word-boundary: log_ preceded by start-of-trimmed,
         # space, tab, ;, &, |, or !
         #
         local funcname

         # strip the line down: remove everything before the log_ call
         # but make sure we don't match _log_ or other_log_
         funcname=""
         case "${line}" in
            *'log_debug'*|*'log_entry'*|*'log_error'*|*'log_fluff'*|\
            *'log_info'*|*'log_vibe'*|*'log_setting'*|*'log_trace'*|\
            *'log_verbose'*|*'log_warning'*)
               # extract: get the part starting with log_
               # but verify the char before it is not [a-zA-Z0-9_]
               local rest="${line}"
               while :
               do
                  case "${rest}" in
                     *log_*)
                        # get prefix before first log_
                        local before="${rest%%log_*}"
                        local after="${rest#*log_}"

                        # check char before log_ (last char of before)
                        local preceding
                        if [ -n "${before}" ]
                        then
                           preceding="${before#"${before%?}"}"
                        else
                           preceding=""
                        fi

                        case "${preceding}" in
                           [a-zA-Z0-9_])
                              # part of another identifier, skip past this match
                              rest="${after}"
                              continue
                           ;;
                        esac

                        # extract the function name
                        local candidate="log_${after%%[[:space:]\"]*}"
                        case "${candidate}" in
                           *'log_debug'*|*'log_entry'*|*'log_error'*|*'log_fluff'*|\
                           *'log_info'*|*'log_vibe'*|*'log_setting'*|*'log_trace'*|\
                           *'log_verbose'*|*'log_warning'*)
                              funcname="${candidate}"
                           ;;

                           *)
                              rest="${after}"
                              continue
                           ;;
                        esac
                        break
                     ;;

                     *)
                        break
                     ;;
                  esac
               done
            ;;
         esac

         if [ -z "${funcname}" ]
         then
            continue
         fi

         log_funcname="${funcname}"

         # check for line continuation
         case "${line}" in
            *\\)
               in_log='continuation'
               log_lineno="${lineno}"
               continue
            ;;
         esac

         # count unescaped double quotes after the function name to detect
         # unclosed strings (literal newlines in quotes)
         local args="${line#*"${funcname}"}"
         local tmp="${args}"
         local count=0

         while :
         do
            case "${tmp}" in
               *'"'*)
                  local left="${tmp%%'"'*}"
                  # check if preceded by backslash
                  case "${left}" in
                     *\\)
                        tmp="${tmp#*'"'}"
                        continue
                     ;;
                  esac
                  count=$((count + 1))
                  tmp="${tmp#*'"'}"
               ;;

               *)
                  break
               ;;
            esac
         done

         # odd number of unescaped quotes means an unclosed string
         if [ $((count % 2)) -ne 0 ]
         then
            in_log='openquote'
            log_lineno="${lineno}"
         fi
      done < "${filename}"

      # unterminated at EOF
      if [ -n "${in_log}" ]
      then
         case "${in_log}" in
            continuation)
               log_error "${filename}:${log_lineno}: \"${log_funcname}\" spans multiple lines (use _${log_funcname} instead)"
            ;;

            openquote)
               log_error "${filename}:${log_lineno}: \"${log_funcname}\" has multiline string argument (use _${log_funcname} instead)"
            ;;
         esac
         if [ "${option_repair}" = 'YES' ]
         then
            inplace_sed -e "${log_lineno}s/^\([[:space:]]*\)${log_funcname}/\1_${log_funcname}/" \
                        -e "${log_lineno}s/\([^_a-zA-Z0-9]\)${log_funcname}/\1_${log_funcname}/" \
                        "${filename}"
            log_info "repaired ${filename}:${log_lineno}"
         fi
         rval=1
      fi
   done

   return ${rval}
}



mulle_bashfunctions_flags()
{
         cat <<'EOF'
These flags are commonly understood by mulle-bash scripts. They belong right
after the command and not anywhere else.
e.g.
   mulle-sde -n -lx exec ls

Your script parses them with `options_technical_flags "$1"` and
and executes them with `options_setup_trace "${MULLE_TRACE}" && set -x`:

   -n, --dry-run                : Don't execute commands, just show them
   -s, --silent                 : Suppress all output except errors
   --silent-but-warn            : Suppress output except warnings and errors
   -v, --verbose                : Enable verbose output (-vv, -vvv for more)

   -ld, --log-debug             : Enable debug logging output
   -le, --log-environment       : Log environment variables and state
   -ls, --log-settings          : Log settings and configuration
   -lx, --log-exekutor          : Log external command execution
   -lt, --trace                 : Enable bash/zsh tracing with line numbers
   -tx, --trace-immediately     : Enable tracing immediately (set -x)
   -tp, --trace-profile         : Enable profiling with timestamps
   -tpwd, --trace-pwd           : Show working directory in trace output
   -tfpwd, --trace-full-pwd     : Show full path in trace output
   -l-                          : Disable all logging flags
   -t-                          : Disable tracing

   --mulle-no-color             : turn off colorization
   --mulle-no-error             : turn off error reporting
   --mulle-list-technical-flags : a short list of available flags

Uppercase variants (e.g., -V, -lD, -lE, -lS, -lX, -lT) don't propagate to
child scripts.

Use the MULLE_TECHNICAL_FLAGS environment variable to forward most of these
flags to other mulle-bash scripts.
EOF
}


main()
{
   #
   # simple option handling
   #
   while [ $# -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -h|--help)
            usage
         ;;

         -f|--force)
            MULLE_FLAG_MAGNUM_FORCE='YES'
         ;;

         --version)
            printf "%s\n" "${MULLE_BASHFUNCTIONS_VERSION}"
            exit 0
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option \"$1\""
            usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   local cmd

   cmd="${1:-libexec-dir}"
   [ $# -eq 0 ] || shift

   MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE_NAME} ${cmd}"

   case "${cmd}" in
      'help')
         usage
      ;;

      'apropos')
         apropos_function "$@" || exit 1
      ;;

      'env')
         echo "\
MULLE_BASHFUNCTIONS_LIBEXEC_DIR=\"${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}\"
MULLE_USERNAME=\"${MULLE_USERNAME}\"
MULLE_HOSTNAME=\"${MULLE_HOSTNAME}\"
MULLE_UNAME=\"${MULLE_UNAME}\""
      ;;

      'embed-boot')
         mulle_boot_embed "$@"
      ;;

      'embed')
         mulle_boot_embed "$@" | mulle_bashfunctions_embed "$@"
      ;;

      'extract-boot')
         mulle_boot_extract "$@"
      ;;

      'extract'|'unembed')
         mulle_boot_extract "$@" | mulle_bashfunctions_extract "$@"
      ;;

      'flags')
         mulle_bashfunctions_flags "$@"
      ;;

      'functions')
         list_functions "$@" || exit 1
      ;;

      globals)
         if [ $# -ne 0 ]
         then
            declare -p | sed 's/^declare -[^ ]*[ ]*//p' | sort | sort -u
         else
            declare -p | sed -n 's/^declare -[^ ]* \(MULLE_[^=]*\)=\(.*\)$/\1=\2/p' | sort | sort -u
         fi
      ;;

      'hostname')
         printf "%s\n" "${MULLE_HOSTNAME}"
      ;;

      'init'|'script')
         fail "Use mulle-sde add --extension \"mulle-nat/file.sh\" instead"
      ;;

      'libexec-dir')
         printf "%s\n" "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}"
      ;;

      'libraries')
         list_libraries "$@" || exit 1
      ;;

      'log-checker')
         include "path"
         include "file"
         log_checker "$@" || exit 1
      ;;

      'load')
         local format
         local check

         [ $# -ne 0 -a "$1" = "--if-missing" ] && check='YES' && shift
         [ $# -ne 0 ] && format="-$1" && shift

         if [ "${check}" = 'YES' ]
         then
            echo "if [ -z \"\${MULLE_BASHGLOBAL_SH}\" ]; then"
         fi

         echo "\
MULLE_BASHFUNCTIONS_LIBEXEC_DIR=\"${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}\"
export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
MULLE_USERNAME=\"${MULLE_USERNAME}\"
export MULLE_USERNAME
MULLE_HOSTNAME=\"${MULLE_HOSTNAME}\"
export MULLE_HOSTNAME
MULLE_UNAME=\"${MULLE_UNAME}\"
export MULLE_UNAME
. \"${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions${format}.sh\""
         if [ "${check}" = 'YES' ]
         then
            echo "fi"
         fi
      ;;


      'common-unames')
         cat <<EOF
android
darwin
dragonfly
freebsd
hpux
linux
mingw
msys
netbsd
openbsd
sunos
windows
EOF
      ;;

      'man')
         man_function "$@" || exit 1
      ;;

      'new')
         new_function "$@" || exit 1
      ;;

      'ncores')
         include "path"
         include "file"
         include "parallel"

         r_get_core_count
         printf "%s\n" "${RVAL}"
      ;;

      'path')
         local format

         [ $# -ne 0 ] && format="-$1"

         echo "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions${format}.sh"
      ;;

      # useful for accessing a single function from the library
      'eval')
         include "path"
         include "file"
         include "case"
         include "parallel"
         include "sort"
         include "url"
         include "version"

         "$@"
         return $?
      ;;

      # useful for accessing a r function from the library
      'r-eval')
         include "path"
         include "file"
         include "case"
         include "parallel"
         include "sort"
         include "url"
         include "version"

         "$@" || return $?
         printf "%s\n" "${RVAL}"
         return 0
      ;;

      'shell')
         printf "%s\n" `ps -h -o cmd -p $$ | awk '{ print $1 }'`
      ;;

      'toc')
         # Try installed location first
         local tocfile="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/../share/mulle-bashfunctions/${MULLE_BASHFUNCTIONS_VERSION}/dox/TOC.md"
         if [ ! -f "${tocfile}" ]
         then
            # Fall back to source location (script directory)
            local scriptdir
            scriptdir="$(cd "$(dirname "${MULLE_EXECUTABLE}")" && pwd -P)"
            tocfile="${scriptdir}/asset/dox/TOC.md"
         fi
         if [ -f "${tocfile}" ]
         then
            cat "${tocfile}"
         else
            fail "TOC.md not found"
         fi
      ;;

      'uname')
         printf "%s\n" "${MULLE_UNAME}"
      ;;

      'username')
         printf "%s\n" "${MULLE_USERNAME}"
      ;;

      'uuid')
         include "path"
         include "file"

         r_uuidgen
         printf "%s\n" "${RVAL}"
      ;;

      'version')
         printf "%s\n" "${MULLE_BASHFUNCTIONS_VERSION}"
      ;;

      'versions')
         list_versions "$@" || exit 1
      ;;

      *)
         usage "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown command \"${cmd}\""
      ;;
   esac
}


_init()
{
   if [ ${ZSH_VERSION+x} ]
   then
     setopt sh_word_split
   fi

   #
   # commands with minimal trap setup. libexec-dir is the most common call
   # and will exit quickly
   #
   if [ $# -eq 1 ]
   then
      case "$1" in
         libexec-dir|library-path)
            printf "%s\n" "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}"
            exit 0
         ;;

         version)
            printf "%s\n" "${MULLE_BASHFUNCTIONS_VERSION}"
            exit 0
         ;;
      esac
   fi

   # shellcheck source=src/mulle-logging.sh
   include "logging" || _internal_fail "include mulle-version.sh fail"
   # shellcheck source=src/mulle-version.sh
   include "version" || _internal_fail "include mulle-version.sh fail"
   # shellcheck source=src/mulle-usage.sh
   include "usage" || _internal_fail "include mulle-usage.sh fail"

   shell_enable_pipefail
   shell_enable_extglob
}


_init "$@"
main "$@"

