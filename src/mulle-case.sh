# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
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
if ! [ ${MULLE_CASE_SH+x} ]
then
MULLE_CASE_SH='included'


_r_tweaked_de_camel_case()
{
   local s="$1"

   local output
   local state
   local collect

   local c

   s="${s//ObjC/Objc}"

   state='start'
   while [ ! -z "${s}" ]
   do
      c="${s:0:1}"
      s="${s:1}"

      case "${state}" in
         'start')
            case "${c}" in
               [A-Z])
                  state="upper";
                  collect="${collect}${c}"
                  continue
               ;;

               *)
                  state="lower"
               ;;
            esac
         ;;

         'upper')
            case "${c}" in
               [A-Z])
                  collect="${collect}${c}"
                  continue
               ;;

               *)
                  if [ ! -z "${output}" -a ! -z "${collect}" ]
                  then
                     if [ ! -z "${collect:1}" ]
                     then
                        output="${output}_${collect%?}_${collect#${collect%?}}"
                     else
                        output="${output}_${collect}"
                     fi
                  else
                     if [ -z "${output}" -a "${#collect}" -gt 1 ]
                     then
                        output="${collect%?}_${collect: -1}"
                     else
                        output="${output}${collect}"
                     fi
                  fi
                  collect=""
                  state="lower"
               ;;
            esac
         ;;

         'lower')
            case "${c}" in
               [A-Z])
                  output="${output}${collect}"
                  collect="${c}"
                  state="upper"
                  continue
               ;;
            esac
         ;;
      esac

      output="${output}${c}"
   done

   if [ ! -z "${output}" -a ! -z "${collect}" ]
   then
      output="${output}_${collect}"
   else
      output="${output}${collect}"
   fi

   RVAL="${output}"
}


#
# r_tweaked_de_camel_case <string>
#
#    This is a camel case to underscore converter that keeps capitalized
#    letters together. It contains a stupid hack for ObjC because it was just
#    too hard to figure that one out.
#
#    Ex. MulleObjCBaseFoundation -> Mulle_ObjC_Base_Foundation
#        FBTroll -> FBTroll
#        FBTrollFB -> FBTroll_FB
#
#        MulleEOFoundation -> Mulle_EO_Foundation
#        MulleEOClassDescription Mulle_EO_Class_Description
#
function r_tweaked_de_camel_case()
{
   # need this for [A-B] to be case sensitive, don't ask
   # https://stackoverflow.com/questions/10695029/why-isnt-the-case-statement-case-sensitive-when-nocasematch-is-off
   LC_ALL=C _r_tweaked_de_camel_case "$@"
}


#
# r_de_camel_case_identifier <string>
#
#    Uses r_tweaked_de_camel_case to de-camel case a string, then turns it
#    into an identifier.
#
#       EO.Foundation -> EO_Foundation
#
function r_de_camel_case_identifier()
{
   r_tweaked_de_camel_case "$1"
   r_identifier "${RVAL}"
}


#
# r_smart_downcase_identifier <string>
#
#    Uses r_de_camel_case_identifier to create an identifier. Then make it all
#    lowercase.
#
#       EO.Foundation -> eo_foundation
#
function r_smart_downcase_identifier()
{
   r_de_camel_case_identifier "$1"
   r_lowercase "${RVAL}"
}


#
# r_smart_upcase_identifier <string>
#
#    Uses r_de_camel_case_identifier to create an identifier. Then makes it all
#    uppercase.
#
#    makes ID_FOO_R from idFooR
#    Ensures that it doesn't make FOO__XXX from FOO_XXX though.
#
function r_smart_upcase_identifier()
{
   r_uppercase "$1"
   r_identifier "${RVAL}"

   if [ "${RVAL}" = "$1" ]
   then
      return
   fi

   r_de_camel_case_identifier "$1"
   r_uppercase "${RVAL}"
}


#
# r_smart_file_upcase_identifier <string>
#
#    Uses r_smart_upcase_identifier to create an uppercase identifier.
#
#    turns mulle-scion into MULLE__SCION to distinguish from
#    MulleScion -> MULLE_SCION
#
function r_smart_file_upcase_identifier()
{
   local s="$1"

   s="${s//-/__}"

   r_uppercase "$s"
   r_identifier "${RVAL}"

   if [ "${RVAL}" = "$s" ]
   then
      return
   fi

   r_de_camel_case_identifier "$s"
   r_uppercase "${RVAL}"
}



fi

:
