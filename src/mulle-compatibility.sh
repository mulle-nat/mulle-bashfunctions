# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
#
#   Copyright (c) 2021 Nat! - Mulle kybernetiK
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
if ! [ ${MULLE_COMPATIBILITY_SH+x} ]
then
MULLE_COMPATIBILITY_SH='included'


#
# shell_enable_pipefail
#
#    Turn on pipefail.
#
function shell_enable_pipefail()
{
   set -o pipefail
}


#
# shell_disable_pipefail
#
#    Turn off pipefail.
#
function shell_disable_pipefail()
{
   set +o pipefail
}


#
# shell_is_pipefail_enabled
#
#    Check if pipefail is enabled.
#    pipefail is recommended and turned on by default in mulle-bashfunctions
#    Returns 0 if yes.
#
function shell_is_pipefail_enabled()
{
   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}


#
# shell_enable_extglob
#
#    Turn on extglob.
#
function shell_enable_extglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt kshglob
      setopt bareglobqual
   else
      shopt -s extglob
   fi
}


#
# shell_disable_extglob
#
#    Turn of extglob.
#    Not recommended for mulle-bashfunctions code.
#
function shell_disable_extglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt bareglobqual
      unsetopt kshglob
   else
      shopt -u extglob
   fi
}


#
# shell_is_extglob_enabled
#
#    Check if extended globbing is enabled. Extended globbing allows use
#    of more regular expressions.
#    Returns 0 if yes.
#
function shell_is_extglob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
   then
      [[ -o kshglob ]]
      return $?
   fi

   shopt -q extglob
}


#
# shell_enable_nullglob
#
#    Enable nullglob. nullglob is turned off by default.
#
function shell_enable_nullglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt nullglob
   else
      shopt -s nullglob
   fi
}


#
# shell_disable_nullglob
#
#    Disable nullglob.
#
function shell_disable_nullglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt nullglob
   else
      shopt -u nullglob
   fi
}


#
# shell_is_nullglob_enabled
#
#    Check if nullglob is enabled.
#    When nullglob is set, non-matching wildcards return an empty result.
#    Returns 0 if so.
#
function shell_is_nullglob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
   then
      [[ -o nullglob ]]
      return $?
   fi
   shopt -q nullglob
}


#
# shell_enable_glob
#
#    Enable globbing
#
function shell_enable_glob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt noglob
   else
      set +f
   fi
}


#
# shell_disable_glob
#
#    Disable globbing
#
function shell_disable_glob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt noglob
   else
      set -f
   fi
}


#
# shell_is_glob_enabled <name>
#
#    Check if globbing is enabled.
#    Globbing turns wildcards into filenames.
#    Returns 0 if yes.
#
function shell_is_glob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
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


#
# shell_is_function <name>
#
#    Check if a function exists under this <name>
#    Returns 0 if yes.
#
function shell_is_function()
{
   if [ ${ZSH_VERSION+x} ]
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


#
# shell_is_builtin_command <name>
#
#    Check if a builtin function exists under this <name>
#    Returns 0 if yes.
#
function shell_is_builtin_command()
{
   if [ ${ZSH_VERSION+x} ]
   then
      case "`LC_C=C whence -w "$1" `" in
         *:*builtin)
            return 0
         ;;
      esac
      return 1
   fi

   [ "`type -t "$1"`" = "builtin" ]
   return $?
}


#
# r_shell_indirect_expand <name>
#
#    In bash this is ${!name}. This function works in zsh as well.
#
#    x=y ; y=22 ; r_shell_indirect_expand "x" ; echo "${RVAL}" -> y
#    x=y ; y=22 ; r_shell_indirect_expand "${x}" ; echo "${RVAL}" -> 22
#
function r_shell_indirect_expand()
{
   local key="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      RVAL="${(P)key}"
   else
      RVAL="${!key}"
   fi
}

#
# shell_is_variable_defined <name>
#
#    Check if a variable with <name> is defined.
#
function shell_is_variable_defined()
{
   local key="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      [[ -n ${(P)key} ]]
      return $?
   fi
   [ "${!key}" ]
}


##
## Special for macros. The default for in a shell script is "supposed to"
## iterate though file names (e.g. for i in *). That's why globbing is on
## by default. In mulle bash scripts, the for loop is often over strings,
## where globbing is no use. Define some aliases, that facilitate string
## fors
##
## .for x in * foo bar
## .do
##    echo "$x"
## .done
##
## Concept inspired by: https://github.com/yoctu/yosh/blob/master/lib/0-type.sh
##
unalias -a

if [ ${ZSH_VERSION+x} ]
then
   ## zsh
   setopt aliases

   alias .for="setopt noglob; for"
   alias .foreachline="setopt noglob; IFS=$'\n'; for"
   alias .foreachword="setopt noglob; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="setopt noglob; IFS=','; for"
   alias .foreachpath="setopt noglob; IFS=':'; for"
   alias .foreachpathcomponent="set -f; IFS='/'; for"
   alias .foreachcolumn="setopt noglob; IFS=';'; for"
   alias .foreachfile="unsetopt noglob; setopt nullglob; IFS=' '$'\t'$'\n'; for"
   alias .do="do
   unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"

else
   ## bash
   shopt -s expand_aliases

   alias .for="set -f; for"
   alias .foreachline="set -f; IFS=$'\n'; for"
   alias .foreachword="set -f; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="set -f; IFS=','; for"
   alias .foreachpath="set -f; IFS=':'; for"
   alias .foreachpathcomponent="set -f; IFS='/'; for"
   alias .foreachcolumn="set -f; IFS=';'; for"
   alias .foreachfile="set +f; shopt -s nullglob; IFS=' '$'\t'$'\n'; for"
   alias .do="do
set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
fi


# syntax sugar for shellcheck
alias .break="break"
alias .continue="continue"

#
# extglob is enabled by default now. I see no real downside
# noglob would be another good default for scripting, but that's possibly
# a bit too surprising when copy/pasting foreign code
#

#  set -e # more pain then gain in the end
#  set -u # weirds up the code a lot with ${y+x} and ${x:-} needed almost
#         # everywhere
shell_enable_extglob
shell_enable_pipefail

fi
:
