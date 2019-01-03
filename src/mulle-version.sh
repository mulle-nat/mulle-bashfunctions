#! /usr/bin/env bash
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
[ ! -z "${MULLE_VERSION_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-version.sh" >&2

MULLE_VERSION_SH="included"


r_get_version_major()
{
   RVAL="${1%%\.*}"
}


r_get_version_minor()
{
   RVAL="${1#*\.}"
   if [ "${RVAL}" = "$1" ]
   then
      RVAL=0
   else
      RVAL="${RVAL%%\.*}"
   fi
}

# make sure 1.8 returns 0
r_get_version_patch()
{
   local prev

   prev="${1#*\.}"
   RVAL="${prev#*\.}"
   if [ "${RVAL}" = "${prev}" ]
   then
      RVAL=0
   else
      RVAL="${RVAL%%\.*}"
   fi
}


#
# version must be <= min_major.min_minor
#
check_version()
{
   local version="$1"
   local min_major="$2"
   local min_minor="$3"

   if [ -z "${version}" ]
   then
      return 1
   fi

   local major
   local minor
   r_get_version_major "${version}"
   major="${RVAL}"

   if [ "${major}" -lt "${min_major}" ]
   then
      return 0
   fi

   if [ "${major}" -ne "${min_major}" ]
   then
      return 1
   fi

   r_get_version_minor "${version}"
   minor="${RVAL}"

   [ "${minor}" -le "${min_minor}" ]
}


#
# Gimme major, minor, patch
# version is like ((major << 20) | (minor << 8) | (patch))
#
_r_version_value()
{
   RVAL="$((${1:-0} * 1048576 + ${2:-0} * 256 + ${3:-0}))"
}


#
# Gimme "${major}.${minor}.${patch}"
#
r_version_value()
{
   local major
   local minor
   local patch

   r_get_version_major "$1"
   major="${RVAL}"
   r_get_version_minor "$1"
   minor="${RVAL}"
   r_get_version_patch "$1"
   patch="${RVAL}"

   _r_version_value "${major}" "${minor}" "${patch}"
}


r_version_value_distance()
{
   RVAL="$(($2 - $1))"
}


r_version_distance()
{
   local value1
   local value2

   r_version_value "$1"
   value1="${RVAL}"
   r_version_value "$2"
   value2="${RVAL}"

   r_version_value_distance "${value1}" "${value2}"
}


# pass in the result of `version_distance found requested
#
# When do we fail ? Assume we have version 2.3.4.
#   Fail for requests for different major
#   Fail for request for any version > 2.3.4
#
is_compatible_version_value_distance()
{
   # major check
   if [ "$1" -ge 1048576 -o "$1" -le -1048575 ]
   then
      return 1
   fi

   if [ "$1" -gt 4096 ]
   then
      return 1
   fi

   [ "$1" -le 0 ]
}


is_compatible_version()
{
   r_version_distance "$1" "$2"
   is_compatible_version_value_distance "${RVAL}"
}

:
