#! /usr/bin/env mulle-bash



log_checker()
{
   log_entry "log_checker" "$@"

   for filename in "$@"
   do
      while IFS= read -r line || [ -n "${line}" ]
      do
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
      done < "${filename}"

   done
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

