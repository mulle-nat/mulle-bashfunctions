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
MULLE_VERSION_SH="included"


get_version_major()
{
   cut -d. -f1 <<< "$1"
}


get_version_minor()
{
   cut -d. -f2 <<< "$1"
}


get_version_patch()
{
   cut -d. -f3 <<< "$1"
}


#
# version must be <= min_major.min_minor
#
check_version()
{
   local version="$1"
   local min_major="$2"
   local min_minor="$3"

   local major
   local minor

   # some cleaning for mulle-bootstrap
   version="`head -1 <<< "${version}"`"
   if [ -z "${version}" ]
   then
      return 0
   fi

   major="`get_version_major "${version}"`"
   if [ "${major}" -lt "${min_major}" ]
   then
      return 0
   fi

   if [ "${major}" -ne "${min_major}" ]
   then
      return 1
   fi

   minor="`get_version_minor "${version}"`"
   [ "${minor}" -le "${min_minor}" ]
}


#
# Gimme major, minor, patch
# version is like ((major << 20) | (minor << 8) | (patch))
#
_version_value()
{
   echo $((${1:-0} * 1048576 + ${2:-0} * 256 + ${3:-0}))
}


#
# Gimme "${major}.${minor}.${patch}"
#
version_value()
{
   _version_value "`get_version_major "$1"`"  "`get_version_minor "$1"`" "`get_version_patch "$1"`"
}


version_value_distance()
{
   echo $(($2 - $1))
}


version_distance()
{
   version_value_distance "`version_value $1`" "`version_value $2`"
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
   is_compatible_version_value_distance "`version_distance "$1" "$2"`"
}


:
