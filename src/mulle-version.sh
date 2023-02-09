#
# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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

if ! [ ${MULLE_VERSION_SH+x} ]
then
MULLE_VERSION_SH='included'


# RESET
# NOCOLOR
#
#    "version" functions handle a simplified form of "semantic versioning".
#    The version format is <major>.<minor>.<patch>, where patch can be
#    8 bits wide (0-255), minor is 12 bits wide (0-4095) and major is also
#    12 bits wide (0-4095).
#
#    A "version-value" is therefore ((major << 20) | (minor << 8) | patch)
#
# TITLE INTRO
# COLOR
#

#
# r_get_version_major <version>
#
#    Pick major out of major.minor.patch <version>
#
function r_get_version_major()
{
   RVAL="${1%%\.*}"
}


#
# r_get_version_major <version>
#
#    Pick minor out of major.minor.patch <version>
#
function r_get_version_minor()
{
   RVAL="${1#*\.}"
   if [ "${RVAL}" = "$1" ]
   then
      RVAL=0
   else
      RVAL="${RVAL%%\.*}"
   fi
}


#
# r_get_version_patch <version>
#
#    Pick patch out of major.minor.patch  version.
#    Ensures that 1.8 returns 0.
#
function r_get_version_patch()
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
# Gimme major, minor, patch
# version is like ((major << 20) | (minor << 8) | (patch))
#
_r_version_value()
{
   RVAL="$((${1:-0} * 1048576 + ${2:-0} * 256 + ${3:-0}))"
}


#
# r_version_value <version>
#
#    Parses <version> as major.minor.patch and computes a 32 bit version-value.
#    This function can deal with missing components and sets them to 0.
#    Cleans out junk.
#
function r_version_value()
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


#
# r_version_value_distance <version-value1> <version-value2>
#
#    Computes the distance between two 32 bit version values.
#
_r_version_value_distance()
{
   RVAL="$(($2 - $1))"
}


#
# r_version_value_distance <version1> <version2>
#
#    Computes the version value distance between version values.
#    The return value in RVAL is the 32 bit distance.
#
function r_version_distance()
{
   local value1
   local value2

   r_version_value "$1"
   value1="${RVAL}"
   r_version_value "$2"
   value2="${RVAL}"

   _r_version_value_distance "${value1}" "${value2}"
}


#
# _is_compatible_version_value_distance <version-value>
#
#    pass in the result of r_version_distance
#
#    When do we fail ? Assume we have version 2.3.4.
#       Fail for requests for different major
#       Fail for request for any version > 2.3.4
#
_is_compatible_version_value_distance()
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


#
# is_compatible_version <version1> <version2>
#
#   Check if version1 is compatible with version2
#
#    When do we fail ? Assume we have version 2.3.4.
#       Fail for requests for different major
#       Fail for request for any version < 2.3.4
#
function is_compatible_version()
{
   r_version_distance "$1" "$2"
   _is_compatible_version_value_distance "${RVAL}"
}

fi
:
