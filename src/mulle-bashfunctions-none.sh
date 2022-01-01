#
#   Copyright (c) 2015-2021 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#

if [ -z "${MULLE_BASHGLOBAL_SH}" ]
then
   MULLE_BASHGLOBAL_SH="included"

   DEFAULT_IFS="${IFS}" # as early as possible

   if [ ! -z "${ZSH_VERSION}" ]
   then
     setopt sh_word_split
     setopt POSIX_ARGZERO
   fi

   if [ -z "${MULLE_EXECUTABLE}" ]
   then
      MULLE_EXECUTABLE="${BASH_SOURCE[0]:-${(%):-%x}}"
      case "${MULLE_EXECUTABLE##*/}" in 
         mulle-bash*.sh)
            MULLE_EXECUTABLE="$0"
         ;;
      esac
   fi

   case "${MULLE_EXECUTABLE##*/}" in 
      mulle-bash*.sh)
         echo "MULLE_EXECUTABLE fail" >&2
         exit 1
      ;;
   esac


   if [ -z "${MULLE_EXECUTABLE_NAME}" ]
   then
      MULLE_EXECUTABLE_NAME="${MULLE_EXECUTABLE##*/}"
   fi

   if [ -z "${MULLE_USER_PWD}" ]
   then
      MULLE_USER_PWD="${PWD}"
      export MULLE_USER_PWD
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME}}"

   MULLE_EXECUTABLE_PWD="${PWD}"
   MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE_NAME}"
   MULLE_EXECUTABLE_PID="$$"

   if [ -z "${MULLE_UNAME}" ]
   then
      case "${BASH_VERSION}" in
         [0123]*)
            MULLE_UNAME="`uname | tr '[:upper:]' '[:lower:]'`"
         ;;

         *)
            MULLE_UNAME="`uname`"
            if [ ! -z "${ZSH_VERSION}" ]
            then
               MULLE_UNAME="${MULLE_UNAME:l}"
            else
               MULLE_UNAME="${MULLE_UNAME,,}"
            fi
         ;;
      esac
      MULLE_UNAME="${MULLE_UNAME%%_*}"
      MULLE_UNAME="${MULLE_UNAME%[36][24]}" # remove 32 64 (hax)

      if [ "${MULLE_UNAME}" = "linux" ]
      then
         read -r MULLE_UNAME < /proc/sys/kernel/osrelease
         case "${MULLE_UNAME}" in
            *-Microsoft)
               MULLE_UNAME="windows"
               MULLE_EXE_EXTENSION=".exe"
            ;;
  
            *)
               MULLE_UNAME="linux"
            ;;
         esac
      fi
   fi


   if [ -z "${MULLE_HOSTNAME}" ]
   then
      case "${MULLE_UNAME}" in
         'mingw'*)
            MULLE_HOSTNAME="`hostname`"
         ;;

         *)
            MULLE_HOSTNAME="`hostname -s`"
         ;;
      esac

      case "${MULLE_HOSTNAME}" in
         \.*)
            MULLE_HOSTNAME="_${MULLE_HOSTNAME}"
         ;;
      esac
   fi

   if [ -z "${MULLE_USERNAME}" ]
   then
      MULLE_USERNAME="${MULLE_USERNAME:-${USERNAME}}" # mingw
      MULLE_USERNAME="${MULLE_USERNAME:-${USER}}"
      MULLE_USERNAME="${MULLE_USERNAME:-${LOGNAME}}"
      MULLE_USERNAME="${MULLE_USERNAME:-`id -nu 2> /dev/null`}"
      MULLE_USERNAME="${MULLE_USERNAME:-cptnemo}"
   fi
fi

if [ -z "${MULLE_BASHLOADER_SH}" ]
then
   MULLE_BASHLOADER_SH="included"

   r_uppercase()
   {
      case "${BASH_VERSION}" in
         [0123]*)
            RVAL="`printf "$1" | tr '[:lower:]' '[:upper:]'`"
         ;;

         *)
            if [ ! -z "${ZSH_VERSION}" ]
            then
               RVAL="${1:u}"
            else
               RVAL="${1^^}"
            fi
         ;;
      esac
   }


   include_executable_library()
   {
      local executable="$1"
      local header_define="$2"
      local libexec_define="$3"
      local filename="$4"

      if [ ! -z "${!header_define}" ]
      then
         return
      fi

      if [ -z "${!libexec_define}" ]
      then
         printf -v "${libexec_define}" "%s" "`"${executable}" libexec-dir`" || exit 1
         eval export "${libexec_define}"
      fi

      . "${!libexec_define}/${filename}" || exit 1
   }


   include_library()
   {
      local s="$1"

      local name
      local tool

      name="${s##*::}"
      if [ "${name}" != "${s}" ]
      then
         tool="${s%::*}"
      fi

      local upper_name

      r_uppercase "${name}"
      upper_name="${RVAL}"

      if [ -z "${tool}" ]
      then
         include_executable_library "mulle-bashfunctions-env" \
                                    "MULLE_${upper_name}_SH" \
                                    "MULLE_BASHFUNCTIONS_LIBEXEC_DIR" \
                                    "mulle-${name}.sh"
         return $?
      fi

      local upper_tool

      r_uppercase "${tool}"
      upper_tool="${RVAL}"

      local suffix

      suffix=""
      if [ "${use_env}" = 'YES' ]
      then
         suffix="-env"
      fi

      include_executable_library "mulle-${tool}${suffix}" \
                                 "MULLE_${upper_tool}_${upper_name}_SH" \
                                 "MULLE_${upper_tool}_LIBEXEC_DIR" \
                                 "mulle-${tool}-${name}.sh"
   }


   include_library_env()
   {
      include_library "$1" "YES"
   }


   __bashfunctions_loader()
   {
      if [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" -a ! -z "$0" ]
      then
         local tmp

         tmp="${0%/*}"
         if [  -f "${tmp}/mulle-bashfunctions.sh" ]
         then
            MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${tmp}"
         fi
      fi

      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] \
         && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" >&2 \
         && exit 1
      :
   }

   __bashfunctions_loader || exit 1
fi
if [ -z "${MULLE_COMPATIBILITY_SH}" ]
then
MULLE_COMPATIBILITY_SH="included"


shell_enable_pipefail()
{
   set -o pipefail
}


shell_disable_pipefail()
{
   set +o pipefail
}


shell_is_pipefail_enabled()
{
   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}


shell_enable_extglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      setopt kshglob
      setopt bareglobqual
   else
      shopt -s extglob
   fi
}


shell_disable_extglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      unsetopt bareglobqual
      unsetopt kshglob
   else
      shopt -u extglob
   fi
}


shell_is_extglob_enabled()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      [[ -o kshglob ]]
      return $?
   fi

   shopt -q extglob
}


shell_enable_nullglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      setopt nullglob
   else
      shopt -s nullglob
   fi
}


shell_disable_nullglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      unsetopt nullglob
   else
      shopt -u nullglob
   fi
}


shell_is_nullglob_enabled()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      [[ -o nullglob ]]
      return $?
   fi
   shopt -q nullglob
}


shell_enable_glob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      unsetopt noglob
   else
      set +f
   fi
}


shell_disable_glob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      setopt noglob
   else
      set -f
   fi
}


shell_is_glob_enabled()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      if [[ -o noglob ]]
      then
         return 1
      fi
      return 0
   fi

   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}


shell_is_function()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      case "`type "$1" `" in
         *function*)
            return 0
         ;;
      esac
      return 1
   fi

   [ "`type -t "$1"`" = "function" ]
   return $?
}


unalias -a

if [ ! -z "${ZSH_VERSION}" ]
then
   setopt aliases

   alias .for="setopt noglob; for"
   alias .foreachline="setopt noglob; IFS=$'\n'; for"
   alias .foreachword="setopt noglob; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="setopt noglob; IFS=','; for"
   alias .foreachpath="setopt noglob; IFS=':'; for"
   alias .foreachcolumn="setopt noglob; IFS=';'; for"
   alias .foreachfile="unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'; for"


   alias .do="do
   unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"

else
   shopt -s expand_aliases

   alias .for="set -f; for"
   alias .foreachline="set -f; IFS=$'\n'; for"
   alias .foreachword="set -f; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="set -f; IFS=','; for"
   alias .foreachpath="set -f; IFS=':'; for"
   alias .foreachcolumn="set -f; IFS=';'; for"
   alias .foreachfile="set +f; shopt +u nullglob; IFS=' '$'\t'$'\n'; for"


   alias .do="do
set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
fi


alias .break="break"
alias .continue="continue"



shell_enable_extglob
shell_enable_pipefail

fi
:
