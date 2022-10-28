# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
#
#   Copyright (c) 2015-2017 Nat! - Mulle kybernetiK
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
if ! [ ${MULLE_URL_SH+x} ]
then
MULLE_URL_SH="included"


# RESET
# NOCOLOR
#
#    parse URLs and retrieve components of an URL
#
#    Functions prefixed "r_" return the result in the global variable RVAL.
#    The return value 0 indicates success.
# TITLE INTRO
# COLOR


#
# r_url_encode <url>
#
#    Escape unsafe characters of <url> as %XX hex.
#    Works nicely if there are few characters that need encoding.
#    "foo bar" -> "foo%20bar"
#
function r_url_encode()
{
   local s="$1"

   local c
   local safe
   local encode

   RVAL=
   while :
   do
      safe="${s%%[^a-zA-Z0-9.~_-]*}"
      RVAL="${RVAL}${safe}"
      s="${s#${safe}}"
      if [ -z "${s}" ]
      then
         break
      fi

      c="${s:0:1}"
      s="${s:1}"
      printf -v encode '%%%02X' "'${c}'"
      RVAL="${RVAL}${encode}"
   done
}


#
# r_url_remove_scheme <url>
#
#    Remove scheme: from <url>. Doesn't work nicely,
#    if there is no scheme in the URL
#    https://www.foo.com/bar?x#22 -> //www.foo.com/bar?x#22
#
function r_url_remove_scheme()
{
   RVAL="${1#*:}"
}


#
# r_url_remove_query <url>
#
#    Remove query part from <url>.
#    https://www.foo.com/bar?x#22 -> https://www.foo.com/bar
#
function r_url_remove_query()
{
   RVAL="${1%\?*}"
}


#
# r_url_remove_fragment <url>
#
#   Remove fragment part from <url>.
#   https://www.foo.com/bar?x#22 -> https://www.foo.com/bar?x
#
function r_url_remove_fragment()
{
   RVAL="${1%#*}"
}

#
# url_has_file_compression_extension <url>
#
#    Heuristic to figure out if an <url> has a file compression extension.
#    zip is not a proper file compression but an archive format (like tar).
#    tgz is the same, so they are not covered.
#
function url_has_file_compression_extension()
{
   r_url_remove_query "$1"
   case "${RVAL}" in
      *.z|*.gz|*.bz2|*.xz)
         return 0
      ;;
   esac
   return 1
}


#
# r_url_remove_file_compression_extension <url>
#
#    Remove the single file compression extension from <url>
#
#    zip is not a proper file compression but an archive format like tar
#    tgz is the same, so they are not covered.
#
function r_url_remove_file_compression_extension()
{
   local url="$1"

   r_url_remove_query "${url}"
   url="${RVAL}"

   RVAL="${url%.z}"
   [ "${RVAL}" != "$url" ] && return
   RVAL="${url%.gz}"
   [ "${RVAL}" != "$url" ] && return
   RVAL="${url%.bz2}"
   [ "${RVAL}" != "$url" ] && return
   RVAL="${url%.xz}"
}



# Following regex is based on https://tools.ietf.org/html/rfc3986#appendix-B with
# additional sub-expressions to split authority into userinfo, host and port
#
readonly MULLE_URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?(/([^?#]*))(\?([^#]*))?(#(.*))?'
#                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑ ↑        ↑  ↑        ↑ ↑
#                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       | 11 rpath |  13 query | 15 fragment
#                    1 scheme:     |  |5 userinfo@             8 :…           10 path    12 ?…       14 #…
#                                  |  4 authority
#                                  3 //…


#
# url_parse <url>
#
#    Parse <url> into "global" variables. Before calling this function, define
#    a local variable block like this:
#
#    local _scheme
#    local _userinfo
#    local _host
#    local _port
#    local _path
#    local _query
#    local _fragment
#
#    url_parse "${URL}"
#
function url_parse()
{
   log_entry "url_parse" "$@"

   local url="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      setopt local_options BASH_REMATCH
   fi

   case "${url}" in
      *://*|/*)
         if ! [[ "${url}" =~ ${MULLE_URI_REGEX} ]]
         then
            return 1
         fi
         _scheme="${BASH_REMATCH[1]}"
         _userinfo="${BASH_REMATCH[6]}"
         _host="${BASH_REMATCH[7]}"
         _port="${BASH_REMATCH[9]}"
         _path="${BASH_REMATCH[10]}"
         _query="${BASH_REMATCH[13]}"
         _fragment="${BASH_REMATCH[15]}"
      ;;

      # hack for git@github.com:mulle-kybernetik-tv/nanovg.git
      *:*)
         _scheme=
         _host="${url%:*}"
         r_url_remove_query "${url##*:}"
         r_url_remove_fragment "${RVAL}"
         _path=${RVAL}
         _userinfo=
         _port=
         case "${_host}" in 
            *@*)
               _userinfo="${_host%%@*}"
               _host="${_host#*@}"
            ;;
         esac
         case "${_host}" in 
            *:*)
               _port="${_host%%:*}"
               _host="${_host#*:}"
            ;;
         esac
         _query=
         _fragment=
      ;;

      *)
         _scheme="${url%:*}"
         r_url_remove_query "${url##*:}"
         r_url_remove_fragment "${RVAL}"
         _path=${RVAL}
         _userinfo=
         _host=
         _port=
         _path=
         _query=
         _fragment=
      ;;
   esac
}


#
# r_url_get_path <url>
#
#    Get path off <url>. <url> can also just be a pathname for a file
#    https://www.foo.com/bar?x#22 -> "/bar"
#
function r_url_get_path()
{
   log_entry "r_url_get_path" "$@"

   local url="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      setopt local_options BASH_REMATCH
   fi

   RVAL=
   case "${url}" in
      *://*|/*)
         [[ "${url}" =~ ${MULLE_URI_REGEX} ]] && RVAL="${BASH_REMATCH[10]}"
      ;;

      *)
         r_url_remove_scheme "${url}"
         r_url_remove_query "${RVAL}"
         r_url_remove_fragment "${RVAL}"
      ;;
   esac
}


fi
:

