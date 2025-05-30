### >> START OF mulle-boot.sh >>
# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
#
# Prelude to be placed at top of each script. Rerun this script either in
# bash or zsh, if not already running in either (which can happen!)
# Allows script to run on systems that either have bash (linux) or
# zsh (macOS) only by default.
#
if [ "${1:-}" != --no-auto-shell ]
then
   _MULLE_UNAME="`uname`"
   case "${_MULLE_UNAME}" in
      [Dd]arwin)
         [ -z "${ZSH_VERSION+x}" ]
      ;;

      *)
         [ -z "${BASH_VERSION+x}" -a -z "${ZSH_VERSION+x}" ]
      ;;
   esac

   if [ $? -eq 0 ]
   then
      exe_shell=
      if [ ! -z "${MULLE_BASH_EXE_SHELL}" ]
      then
         if ! exe_shell="`command -v "${MULLE_BASH_EXE_SHELL}"`"
         then
            if [ "${MULLE_BASH_EXE_SHELL_STRICT}" = 'YES' ]
            then
               echo "Desired MULLE_BASH_EXE_SHELL \"${MULLE_BASH_EXE_SHELL}\" not found" >&2
               exit 1
            fi
         fi
      fi
      if [ -z "${exe_shell}" ]
      then
         case "${_MULLE_UNAME}" in
            [Dd]arwin)
               exe_shell="`command -v "zsh" `"
               exe_shell="${exe_shell:-zsh}" # for error if not installed
            ;;

            *)
               exe_shell="`command -v "bash" `"
               exe_shell="${exe_shell:-`command -v "zsh" `}"
               exe_shell="${exe_shell:-bash}" # for error if not installed
            ;;
         esac
      fi
      script="$0"

      #
      # Quote incoming arguments for shell expansion
      #
      args=""
      for arg in "$@"
      do
         # True bourne sh doesn't know ${a//b/c} and <<<
         case "${arg}" in
            *\'*)
               # Use cat instead of echo to avoid possible echo -n
               # problems. Escape single quotes in string.
               arg="`cat <<EOF | sed -e s/\'/\'\\\"\'\\\"\'/g
${arg}
EOF
`"
            ;;
         esac
         if [ -z "${args}" ]
         then
            args="'${arg}'"
         else
            args="${args} '${arg}'"
         fi
      done

      #
      # bash/zsh will use arg after -c <arg> as $0, convenient!
      #
      exec "${exe_shell}" -c ". ${script} --no-auto-shell ${args}" "${script}"
   fi
else
   shift  # get rid of --no-auto-shell
fi

if [ ! -z "${POSIXLY_CORRECT+x}" ]
then
   set +o posix  # turn off posix
fi

#
# leading backslash ? looks like we're getting called from
# mingw via a .BAT or so. Correct this now
#
case "$PATH" in
   "\\"*)
      PATH="${PATH//\\/\/}"
   ;;
esac

### << END OF mulle-boot.sh <<
