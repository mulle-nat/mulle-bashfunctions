# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
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
#   POSSIBILITY OF SUCH DAMAGE.
#

# double inclusion of this file is OK!
if ! [ ${MULLE_BASHLOADER_SH+x} ]
then
   MULLE_BASHLOADER_SH="included"

   r_uppercase()
   {
      case "${BASH_VERSION:-}" in
         [0123]*)
            RVAL="`printf "%s" "$1" | tr '[:lower:]' '[:upper:]'`"
         ;;

         *)
            if [ ${ZSH_VERSION+x} ]
            then
               RVAL="${1:u}"
            else
               RVAL="${1^^}"
            fi
         ;;
      esac
   }


   r_include_path()
   {
      local executable="$1"
      local filename="$2"
      local libexec_define="$3"

      local value

      if [ ${ZSH_VERSION+x} ]
      then
         value="${(P)libexec_define}"
      else
         value="${!libexec_define}"
      fi

      if [ -z "${value}" ]
      then
         value="`"${executable}" libexec-dir`" || fail "Could not execute ${executable} libexec-dir successfully ($PATH)"
         printf -v "${libexec_define}" "%s" "${value}" 
         eval export "${libexec_define}"
      fi

      RVAL="${value}/${filename}"
   }



   include_executable_library()
   {
#      local executable="$1"
#      local filename="$2"
#      local libexec_define="$3"
      local includeguard="$4"

      local value

      if [ ${ZSH_VERSION+x} ]
      then
         value="${(P)includeguard}"
      else
         value="${!includeguard}"
      fi

      if [ ! -z "${value}" ]
      then
         return
      fi

      r_include_path "$@"

       . "${RVAL}" || exit 1

      printf -v "${includeguard}" "YES"
   }

   # local _executable
   # local _filename
   # local _libexecdir
   # local _includeguard
   #
   __parse_include_specifier()
   {
      local s="$1"
      local default_namespace="${2:-mulle}"  # default namespace (mulle)

      local name

      name="${s##*::}"

      local upper_name

      r_identifier "${name}"
      r_uppercase "${RVAL}"
      upper_name="${RVAL}"

      # short-cut for "file" (mulle-bashfunctions) and "file" "my" (my-bashfunctions)
      if [ "${name}" = "${s}" ]
      then
         if [ "${default_namespace}" = "mulle" ]
         then
            _executable="mulle-bashfunctions"
            _filename="mulle-${name}.sh"
            _libexecdir="MULLE_BASHFUNCTIONS_LIBEXEC_DIR"
            _includeguard="MULLE_${upper_name}_SH"
            return 0
         fi

         r_identifier "${default_namespace}"
         upper_default_namespace="${RVAL}"

         _executable="${default_namespace}-bashfunctions"
         _filename="${default_namespace}-${name}.sh"
         _libexecdir="${upper_default_namespace}_BASHFUNCTIONS_LIBEXEC_DIR"
         _includeguard="${upper_default_namespace}_${upper_name}_SH"
         return 0
      fi

      local tool

      # here we are in "tool::file" (mulle) and "tool::file" "my"
      tool="${s%::*}"

      local namespace

      case "${s}" in
         *-*)
            namespace="${tool%%-*}"
            tool="${tool#*-}"
         ;;

         *)
            namespace="${default_namespace}"
         ;;
      esac

      r_concat "${namespace}" "${tool}" "-"
      tool="${RVAL}"

      local upper_tool

      r_identifier "${tool}"
      r_uppercase "${RVAL}"
      upper_tool="${RVAL}"

      _executable="${tool}"
      _filename="${tool}-${name}.sh"
      _libexecdir="${upper_tool}_LIBEXEC_DIR"
      _includeguard="${upper_tool}_${upper_name}_SH"
   }


   # use <tool>::<name> scheme
   #
   # if your MULLE_EXECUTABLE has a prefix "<foo>-" and "<tool>" does not
   # have a prefix, the prefix will be prepended. If tool is empty, then
   # "bashfunctions" will be used. e.g. your MULLE_EXECUTABLE is "my-grep"
   # and you pass "bar" it will look for "libexec/my-bashfunctions/bar.sh"
   #
   # Examples:
   #
   #       s     | Produces call                    | Expected call return                      | Include define
   # ------------|----------------------------------|-------------------------------------------|----------------
   # "a::b"      | `mulle-a libexecdir`             | "/libexec/mulle-a/mulle-a-b.sh"           | `MULLE_A_B_SH`
   # "your-a::b" | `your-a libexecdir`              | "/libexec/your-a/your-a-b.sh"             | `YOUR_A_B_SH`
   # "b"         | `mulle-bashfunctions libexecdir` | "/libexec/mulle-bashfunctions/mulle-b.sh" | `MULLE_B_SH`
   #
   include()
   {
   #   local s="$1"
   #   local namespace="${2:-}"  # default namespace, possibly not useful

      local _executable
      local _filename
      local _libexecdir
      local _includeguard

      __parse_include_specifier "$@"

      include_executable_library "${_executable}" \
                                 "${_filename}" \
                                 "${_libexecdir}" \
                                 "${_includeguard}"
   }


   __bashfunctions_loader()
   {
      # not sure about this
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
