# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
# shellcheck disable=SC2196 # grep -E
# shellcheck disable=SC2197 # grep -F
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
if ! [ ${MULLE_VERSION_QUALIFIER_SH+x} ]
then
MULLE_VERSION_QUALIFIER_SH='included'

# RESET
# NOCOLOR
#
#    This is some old code that got superseded by mulle-semver. Some
#    of the same functionality is used by mulle-bash to query for compatible
#    versions. No functions are publically documented here.
#
# TITLE INTRO
# COLOR
#

#
# versions_sort <sortflags>
#
#    Sort stdin version numbers in numeric order. So with the default sort
#       10.1.2, 9.1.0, 9.22.0, 9.3.0 ->  9.1.0, 9.3.0, 9.22.0, 10.1.2
#    or when sorting reverse (sortflags="r")
#       10.1.2, 9.1.0, 9.22.0, 9.3.0 ->  10.1.2, 9.22.0, 9.3.0, 9.1.0
#
_versions_sort()
{
   local sortflags="$1"

   sort -u -t. -k "1,1n${sortflags}" -k "2,2n${sortflags}" -k "3,3n${sortflags}"
}

#
# _versions_find_next <version> <version> <sortflags>
#
#
#    Plop our version in, sort and pick the ones after ours
#
_versions_find_next()
{
   local versions="$1"
   local version="$2"
   local sortflags="$3"

   #
   # If ours is not in there yet, plop it in
   #
   if ! grep -F -q -s -x "${version}" <<< "${versions}"
   then
      r_add_line "${versions}" "${version}"
      versions="${RVAL}"
   fi

   # Now sort again and pick the one after ours
   versions="`_versions_sort ${sortflags} <<< "${versions}" `"

   r_escaped_sed_pattern "${version}"

   # delete all lines up to pattern, then implicitly print and quit
   # sed -e "0,/^${RVAL}\$/d" -e '{q;}' <<< "${versions}"

   # want a list of applicable versions
   sed -e "0,/^${RVAL}\$/d" <<< "${versions}"
}


#
# _versions_operation <versions> <operation> <version>
#
#    will filter versions according to operation and version
#    the result will be sorted in ascending order
#
_versions_operation()
{
   local versions="$1"
   local operation="$2"
   local version="$3"

   case "${operation}" in
      '>=')
         grep -F -x "${version}" <<< "${versions}"
         _versions_find_next "${versions}" "${version}"
      ;;

      '>')
         _versions_find_next "${versions}" "${version}"
      ;;

      '<=')
         _versions_find_next "${versions}" "${version}" "r" | _versions_sort
         grep -F -x "${version}" <<< "${versions}"
      ;;

      '<')
         _versions_find_next "${versions}" "${version}" "r" | _versions_sort
      ;;

      '==')
         grep -F -x "${version}" <<< "${versions}"
      ;;

      '!=')
         _versions_sort <<< "${versions}"  | \
            grep -F -x -v "${version}" | \
            "${_choose}" -1
      ;;

      *)
         _internal_fail "unknown operator \"${operator}\""
      ;;
   esac

   return 0
}


#
# A small parser
#

_r_versions_qualify_s()
{
#  log_entry "r_versions_qualify_s" "${_s}" "$@"

   local versions="$1"

   local operator
   local version

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      "("*)
         _s="${_s:1}"
         _r_versions_qualify "${versions}"

         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
#         if [ "${_closer}" != 'YES' ]
#         then
            if [ "${_s:0:1}" != ")" ]
            then
               fail "Closing ) missing at \"${_s}\" of versions qualifier \"${_qualifier}\""
            fi
            _s="${_s:1}"
#         fi
         return
      ;;

      '>='*|'<='*|'=='*|'!='*)
         operator="${_s:0:2}"
         _s="${_s:2}"
      ;;

      '<>'*)
         operator='!='
         _s="${_s:2}"
      ;;

      '<'*|'>'*)
         operator="${_s:0:1}"
         _s="${_s:1}"
      ;;

      '='*)
         operator='=='
         _s="${_s:1}"
      ;;

      [0-9]*)
         operator='=='
      ;;

      "")
         fail "Missing expression after versions qualifier \"${_qualifier}\""
      ;;

      *)
         fail "Unknown command at \"${_s}\" of versions qualifier \"${_qualifier}\""
      ;;
   esac

   ## fall thru for common operation code
   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   version="${_s%%[ )]*}"
   _s="${_s#"${version}"}"

   #log_entry tags_match "${versions}" "${key}"
   RVAL="`_versions_operation "${versions}" "${operator}" "${version}"`" || exit 1
}


_r_versions_qualify_i()
{
#  log_entry "r_versions_qualify_i" "${_s}" "$@"
   local versions="$1"
   local result="$2"

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      [Aa][Nn][Dd]*)
         _s="${_s:3}"
         r_versions_qualify "${versions}"
         RVAL="`grep -F -x -f <( echo "${result}") <<< "${RVAL}" `"
         return 0
      ;;

      [Oo][Rr]*)
         _s="${_s:2}"
         r_versions_qualify "${versions}"
         r_add_line "${result}" "${RVAL}"

         RVAL="`sort -u <<< "${RVAL}"`"
         return 0
      ;;

      ")")
         RVAL="${result}"
         return 0
      ;;

      "")
         RVAL="${result}"
         return 0
      ;;
   esac

   fail "Unexpected expression at ${_s} of versions qualifier \"${_qualifier}\""
}


_r_versions_qualify()
{
#  log_entry "r_versions_qualify" "${_s}" "$@"

   local versions="$1"

   local result

   _r_versions_qualify_s "${versions}"
   result="${RVAL}"

   while :
   do
      _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
      case "${_s}" in
         ")"*|"")
            break
         ;;
      esac
      _r_versions_qualify_i "${versions}" "${result}"
      result="${RVAL}"
   done

   RVAL="${result}"
}


#
# versions_filter <versions> <filter>
#
#   Filter a list of <versions> with filter, picking out the "best" version
#   that matches <filter>
#
#   Filter syntax:  >= 1.0.1 AND < 1.0.2
#
versions_filter()
{
   local versions="$1"
   local filter="$2"

   local _choose

   # used for error messages
   # pick newest by default
   _choose='tail'

   filter="${filter#"${filter%%[![:space:]]*}"}" # remove leading whitespace characters

   case "${filter}" in
      [Oo][Ll][Dd][Ee][Ss][Tt]:*)
         filter="${filter:7}"
         _choose='head'
      ;;

      [Nn][Ee][Ww][Ee][Ss][Tt]:*)
         filter="${filter:7}"
         _choose='tail'
      ;;
   esac

   local _qualifier

   _qualifier="${filter}"

   if [ -z "${filter}" ]
   then
      filter=">= 0.0.0"
   fi

   local _s
   #local _closer

   # used to traverse the string
   _s="${filter}"

   _r_versions_qualify "${versions}"
   if [ ! -z "${RVAL}" ]
   then
      "${_choose}" -1 <<< "${RVAL}"
   fi

   return 0
}

# ###
# ### THIS IS OLD CODE from mulle-fetch, that got superseded by mulle-semver
# ###
# tags_grep_versions()
# {
#    sed -n -e '/^[0-9]*\.[0-9]*\.[0-9]*/p' \
#           -e 's/^.*[a-zA-Z_-]\([0-9]*\.[0-9]*\.[0-9]*\)$/\1/p'
# }
#
#
# # tags_filter()
# {
#    log_entry "tags_filter" "$@"
#
#    local tags="$1"
#    local filter="$2"
#
#    local versions
#    local version
#
#    versions="`tags_grep_versions <<< "${tags}" `" || exit 1
#
#    version="`versions_filter "${versions}" "${filter}" `" || exit 1
#    if [ -z "${version}" ]
#    then
#       RVAL=""
#       return 0
#    fi
#
#    #
#    # map version number back to tags
#    #
#    local pattern
#
#    r_escaped_grep_pattern "${version}"
#    pattern="^${RVAL}$|[a-zA-Z_-]${RVAL}\$"
#
#    grep -E "${pattern}" <<< "${tags}" | head -1
# }
#
#
# is_tags_filter()
# {
#    log_entry "is_tags_filter" "$@"
#
#    local filter="$1"
#
#    filter="${filter#"${filter%%[![:space:]]*}"}" # remove leading whitespace characters
#    case "${filter}" in
#       [Oo][Ll][Dd][Ee][Ss][Tt]:*)
#          return 0
#       ;;
#
#       [Nn][Ee][Ww][Ee][Ss][Tt]:*)
#          return 0
#       ;;
#    esac
#
#    case "${filter}" in
#       *' '[Aa][Nn][Dd]' '*|*' '[Oo][Rr]' '*|*'<'*|*'>'*|*'='*)
#          return 0
#       ;;
#    esac
#
#    return 1
# }
#
fi
:
