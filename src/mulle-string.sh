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
if ! [ ${MULLE_STRING_SH+x} ]
then
MULLE_STRING_SH='included'

[ -z "${MULLE_BASHGLOBAL_SH}" ]    && _fatal "mulle-bashglobal.sh must be included before mulle-file.sh"
[ -z "${MULLE_COMPATIBILITY_SH}" ] && _fatal "mulle-compatibility.sh must be included before mulle-string.sh"


# RESET
# NOCOLOR
#
#    Assortment of various string functions.
#
#    Functions prefixed "r_" return the result in the global variable RVAL.
#    The return value 0 indicates success.
#
# TITLE INTRO
# COLOR



# ####################################################################
#                            Conversion
# ####################################################################
#
# RESET
# NOCOLOR
#
#    conversion function do simple conversions such as turning a string
#    uppercase or removing whitespace. The value in these functions is
#    portability across zsh and older bash versions.
#
# SUBTITLE Conversion
# COLOR

#
# r_trim_whitespace <string>
#
#   Remove surrounding whitespace from a <string>. Does not touch whitespace in
#   the string.
#   "  VfL Bochum   1848  " -> "VfL Bochum   1848"
#
function r_trim_whitespace()
{
   # taken from:
   # https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
   RVAL="$*"
   RVAL="${RVAL#"${RVAL%%[![:space:]]*}"}"
   RVAL="${RVAL%"${RVAL##*[![:space:]]}"}"
}




#
# r_upper_firstchar <s>
#
#    Turn the first character of <s> into uppercase.
#    Example: "vfl Bochum" -> "Vfl Bochum"
#
function r_upper_firstchar()
{
   case "${BASH_VERSION:-}" in
      [0123]*)
         RVAL="`printf "%s" "${1:0:1}" | tr '[:lower:]' '[:upper:]'`"
         RVAL="${RVAL}${1:1}"
      ;;

      *)
         if [ ${ZSH_VERSION+x} ]
         then
            RVAL="${1:0:1}"
            RVAL="${RVAL:u}${1:1}"
         else
            RVAL="${1^}"
         fi
      ;;
   esac
}


#
# r_capitalize <s> ...
#
#    Turn the first character of <s> into uppercase. The remaining characters
#    become lowercase.
#    Example: "VFL Bochum" -> "Vfl bochum"
#
function r_capitalize()
{
   r_lowercase "$@"
   r_upper_firstchar "${RVAL}"
}


#
# r_uppercase <s>
#
#    Turn all character of <s> into uppercase.
#    Example: "VFL Bochum" -> "VFL BOCHUM"
#
function r_uppercase()
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

#
# r_lowercase <s>
#
#    Turn all character of <s> into uppercase.
#    Example: "VfL Bochum" -> "vfl bochum"
#
function r_lowercase()
{
   case "${BASH_VERSION:-}" in
      [0123]*)
         RVAL="`printf "%s" "$1" | tr '[:upper:]' '[:lower:]'`"
      ;;

      *)
         if [ ${ZSH_VERSION+x} ]
         then
            RVAL="${1:l}"
         else
            RVAL="${1,,}"
         fi
      ;;
   esac
}


#
# r_identifier <s>
#
#   replace any non-identifier characters in <s> with '_'
#   Example: foo|bar becomes foo_bar
#
function r_identifier()
{
   # works in bash 3.2
   # may want to disambiguate mulle-scion and MulleScion with __
   # but it looks surprising for mulle--testallocator
   #
   RVAL="${1//-/_}" # __
   RVAL="${RVAL//[^a-zA-Z0-9]/_}"
   case "${RVAL}" in
      [0-9]*)
         RVAL="_${RVAL}"
      ;;
   esac
}


#
# r_extended_identifier <s>
#
#   An extended identifier can start and contain any letter digit
#   and +-=:._. It' assumed that these characters need to quoting
#
#   Example: f.oo|b-ar becomes f.oo_b-ar
#
function r_extended_identifier()
{
   RVAL="${1//[^a-zA-Z0-9+:.=_-]/_}"
}



# ####################################################################
#                            Concatenation
# ####################################################################
#
# RESET
# NOCOLOR
#
#    concat functions append two strings, possibly separated by a separator
#    string. Care is taken, that an empty string does not produce a leading
#    or dangling separator. Some functions go a step further and remove
#    duplicate and leading/dangling separators, which are considered ugly.
#
#    append functions do not use a separator.
#
# SUBTITLE Concatenation
# COLOR

#
# r_append <s1> <s2>
#
#   Concatenates two strings. Same as "${s1}${s2}"
#   "a" "b" -> "ab"
#
function r_append()
{
   RVAL="${1}${2}"
}

#
# r_concat <s1> <s2> [separator]
#
#    Concatenates two strings with a separator in between.
#    If one or both strings are empty, the separator is omitted.
#    This function does not remove duplicate separators.
#
#   "a" "b"       -> "a b"
#   "" "a"        -> "a"
#   "a " " b" "-" -> "a - b"
#   "a-" "-b" "-" -> "a---b"
#
function r_concat()
{
   local separator="${3:- }"

   if [ -z "${1}" ]
   then
      RVAL="${2}"
   else
      if [ -z "${2}" ]
      then
         RVAL="${1}"
      else
         RVAL="${1}${separator}${2}"
      fi
   fi
}


#
# r_concat_unique <s1> <s2> [separator]
#
#    Concatenates s2 unto s1, unless s2 already exists in s1 (delimited by
#    separator).
#    If one or both strings are empty, the separator is omitted.
#    This function does not remove duplicate separators.
#
#   "a" "b"   -> "a b"
#   "a b" "a" -> "a b"
#   "a b" "b" -> "a b"
#   "a b" "c" -> "a b c"
#
function r_concat_unique()
{
   local separator="${3:- }"

   case "${separator}${1}${separator}" in
      *${separator}${2}${separator}*)
         RVAL="${1}"
         return 0
      ;;
   esac

   r_concat "$@"
}

# old name
function r_concat_if_missing()
{
   r_concat_unique "$@"
}


#
# r_remove_duplicate_separators <s1> [separator]
#
#    Removes all duplicate separators. The default separator is " ".
#    "//x///y//" -> "/x/y/"
#
r_remove_duplicate_separators()
{
   local s="$1"
   local separator="${2:- }"

   local escaped
   local dualescaped
   local replacement

   printf -v escaped '%q' "${separator}"

   dualescaped="${escaped//\//\/\/}"
   replacement="${separator}"
   case "${separator}" in
      */*)
         replacement="${escaped}"
      ;;
   esac

   local old

   RVAL="${s}"
   old=''
   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL//${dualescaped}${dualescaped}/${replacement}}"
   done
}


#
# r_remove_ugly <s1> [separator]
#
#    Removes separators from front and back. Removes duplicate separators from
#    the middle. Works for a "common" set of separators.
#    Mainly used to clean up filepaths.
#
#    "//x//y//"   -> "x/y"
#
r_remove_ugly()
{
   local s="$1"
   local separator="${2:- }"

   local escaped
   local dualescaped
   local replacement

   printf -v escaped '%q' "${separator}"

   dualescaped="${escaped//\//\/\/}"
   replacement="${separator}"
   case "${separator}" in
      */*)
         replacement="${escaped}"
      ;;
   esac

   local old

   RVAL="${s}"
   old=''
   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL##[${separator}]}"
      RVAL="${RVAL%%[${separator}]}"
      RVAL="${RVAL//${dualescaped}${dualescaped}/${replacement}}"
   done
}

#
# r_colon_concat <s1> <s2>
#
#    concatenate strings, separating them with a ':'
#    use for PATHs. This function removes duplicate ':' as well as leading
#    and trailing ':'
#
function r_colon_concat()
{
   r_concat "$1" "$2" ":"
   r_remove_ugly "${RVAL}" ":"
}

#
# r_colon_concat_if_missing <s1> <s2>
#
#    Concatenates s2 unto s1, unless s2 already exists in s1 delimted by ':'
#    Useful for PATHs. This function removes duplicate ':' as well as leading
#    and trailing ':'
#
# "/usr/bin:/usr/local/bin"  "/bin"      -> "/usr/bin:/usr/local/bin:/bin"
# "/usr/bin:/usr/local/bin"  "/usr/bin"  -> "/usr/bin:/usr/local/bin"
#
function r_colon_concat_if_missing()
{
   r_concat_if_missing "$1" "$2" ":"
   r_remove_ugly "${RVAL}" ":"
}


#
# r_comma_concat <s1> <s2>
#
#    concatenate strings, separating them with a ','
#    use for lists w/o empty elements. This function removes duplicate ','
#    as well as leading and trailing ','.
#
function r_comma_concat()
{
   r_concat "$1" "$2" ","
   r_remove_ugly "${RVAL}" ","
}


#
# r_comma_concat_if_missing <s1> <s2>
#
#    Concatenates s2 unto s1, unless s2 already exists in s1 delimted by ','
#    Useful for item lists. This function removes duplicate ',' as well as
#    leading and trailing ','
#
# "/usr/bin:/usr/local/bin"  "/bin"      -> "/usr/bin:/usr/local/bin:/bin"
# "/usr/bin:/usr/local/bin"  "/usr/bin"  -> "/usr/bin:/usr/local/bin"
#
function r_comma_concat_if_missing()
{
   r_concat_if_missing "$1" "$2" ","
   r_remove_ugly "${RVAL}" ","
}


#
# r_semicolon_concat <s1> <s2>
#
#    concatenate strings, separating them with a ';'
#    use for CSV. This function does not remove duplicate ';' or leading or
#    trailing ones.
#
function r_semicolon_concat()
{
   r_concat "$1" "$2" ";"
}


#
# r_slash_concat <s1> <s2>
#
#    concatenate strings, separating them with a '/'.
#    Use for filepaths, as this is "cross-platform", because the paths on
#    MINGW are converted already from '\' to '/'.
#    This function removes duplicate '/' but leaves trailing and leading '/'
#    intact.
#
function r_slash_concat()
{
   r_concat "$1" "$2" "/"
   r_remove_duplicate_separators "${RVAL}" "/"
}




# ####################################################################
#                            Lists
# ####################################################################
#
# RESET
# NOCOLOR
#
#    A "list" is a string that consists of substrings (items), separated by a
#    separator string. A special sort of "list" uses the linefeed ($'\n') as
#    the item separator. Here the item is called a "line" and the list is
#    called "lines". There is extensive support for handling such line lists.
#
# SUBTITLE Lists
# COLOR

#
# r_list_remove <list> <value> [separator]
#
#   remove a value from a list.
#   Example:
#   r_list_remove "a b c" "b" will return "a c"
#
function r_list_remove()
{
   local sep="${3:- }"

   RVAL="${sep}$1${sep}//${sep}$2${sep}/}"
   RVAL="${RVAL##"${sep}"}"
   RVAL="${RVAL%%"${sep}"}"
}


#
# r_list_remove <list> <value>
#
#    remove value from a colon separated list
#
function r_colon_remove()
{
   r_list_remove "$1" "$2" ":"
}


#
# r_comma_remove <list> <value>
#
#    Remove value from a comma separated list.
#
function r_comma_remove()
{
   r_list_remove "$1" "$2" ","
}

#
# r_add_line <lines> <line>
#
#   Add a <line> to a <lines> which consists of zero, one or multiple
#   substrings separated by linefeeds.
#
#   this function suppresses empty lines. To not suppress empty lines
#   use r_add_line_lf (in 'array')
#
function r_add_line()
{
   if [ ! -z "${1:0:1}" -a ! -z "${2:0:1}" ]
   then
      RVAL="$1"$'\n'"$2"
   else
      RVAL="$1$2"
   fi
}


#
# r_remove_line <lines> <search>
#
#    Remove a line from a string that contains zero, one or multiple
#    substrings separated by linefeeds.
#
#    Multiple occurences will be deleted
#
function r_remove_line()
{
   local lines="$1"
   local search="$2"

   local line

   local delim

   delim=""
   RVAL=

   .foreachline line in ${lines}
   .do
      if [ "${line}" != "${search}" ]
      then
         RVAL="${RVAL}${delim}${line}"
         delim=$'\n'
      fi
   .done
}


#
# r_remove_line_once <lines> <search>
#
#    Remove a line from a string that contains zero, one or multiple
#    substrings separated by linefeeds.
#
#    Only one occurence will be deleted
#
function  r_remove_line_once()
{
   local lines="$1"
   local search="$2"

   local line

   local delim

   delim=""
   RVAL=

   .foreachline line in ${lines}
   .do
      if [ -z "${search}" -o "${line}" != "${search}" ]
      then
         RVAL="${RVAL}${delim}${line}"
         delim=$'\n'
      else 
         search="" 
      fi
   .done
}


#
# r_get_last_line <lines>
#
#    Retrieve the last line from a string that contains zero, one or multiple
#    substrings separated by linefeeds.
#
function  r_get_last_line()
{
  RVAL="$(sed -n '$p' <<< "$1")" # get last line
}


#
# r_line_at_index <lines> <index>
#
#    Retrieve a line by its index (which starts at 0) from a string that
#    contains zero, one or multiple substrings separated by linefeeds..
#
function r_line_at_index()
{
   RVAL="$(sed -n -e "$(( $2 + 1 ))p" <<< "$1")"
}


#
# r_remove_last_line <lines>
#
#    Remove the last line from a string that contains zero, one or multiple
#    substrings separated by linefeeds.
#
function r_remove_last_line()
{
   RVAL="$(sed '$d' <<< "$1")"  # remove last line
}


#
# find_item <s> <search> [separator]
#
#    Check if a search string is contained as a substring of a string s. The
#    string consists of separated by separator, which by default is the ','.
#
#    Returns 0 if found, 1 if not found
#
#    can't have linefeeds as delimiter
#    e.g. find_item "a,b,c" b -> 0
#         find_item "a,b,c" d -> 1
#         find_item "a,b,c" "," -> 1
#
function find_item()
{
   local line="$1"
   local search="$2"
   local delim="${3:-,}"

   shell_is_extglob_enabled || _internal_fail "need extglob enabled"

   if [ ${ZSH_VERSION+x} ]
   then
      case "${delim}${line}${delim}" in
         *"${delim}${~search}${delim}"*)
            return 0
         ;;
      esac
   else
      case "${delim}${line}${delim}" in
         *"${delim}${search}${delim}"*)
            return 0
         ;;
      esac
   fi      
   return 1
}


#
# find_line is fairly critical for mulle-sourcetree walk, which
# is the slowest operation and most used operation. Don't dick
# around with this without profiling!
#
_find_empty_line_zsh()
{
   local lines="$1"

   case "${lines}" in 
      *$'\n'$'\n'*)
         return 0
      ;;
   esac

   return 1
}


# zsh:
# this is faster than calling grep -F externally (for small arrays)
# this is faster than while read line <<< lines
# this is faster than case ${lines} in 
#
_find_line_zsh()
{
   local lines="$1"
   local search="$2"

   if [ -z "${search:0:1}" ]
   then
      if [ -z "${lines:0:1}" ]
      then
         return 0
      fi

      _find_empty_line_zsh "${lines}"
      return $?
   fi

   local line

   .foreachline line in ${lines}
   .do
      if [ "${line}" = "${search}" ]
      then
         return 0
      fi
   .done

   return 1
}


#
# find_line <lines> <line>
#
#    Check if a substring <line> is contained in the <lines> string, which
#    consists of substrings separated by linefeed.
#
#    Returns 0 if found, 1 if not found
#
function find_line()
{
   # bash:
   # this is faster than calling grep -F externally
   # this is faster than while read line <<< lines
   # this is faster than for line in lines
   #
   # ZSH is apparently super slow in pattern matching
   if [ ${ZSH_VERSION+x} ]
   then
      _find_line_zsh "$@"
      return $?
   fi

   local lines="$1"
   local search="$2"

   local escaped_lines
   local pattern

# ensure leading and trailing linefeed for matching and $'' escaping
   printf -v escaped_lines "%q" "
${lines}
"

# add a linefeed here to get also $'' escaping
   printf -v pattern "%q" "${search}
"
   # remove $'
   pattern="${pattern:2}"
   # remove \n'
   pattern="${pattern%???}"

   local rval

   rval=1

   shell_is_extglob_enabled || _internal_fail "extglob must be enabled"

   if [ ${ZSH_VERSION+x} ]
   then
      case "${escaped_lines}" in
         *"\\n${~pattern}\\n"*)
            rval=0
         ;;
      esac
   else
      case "${escaped_lines}" in
         *"\\n${pattern}\\n"*)
            rval=0
         ;;
      esac
   fi

   return $rval
}


#
# r_count_lines <lines>
#
#    Count the number of lines contained in <lines>.
#
function r_count_lines()
{
   local array="$1"

   RVAL=0

   local line

   .foreachline line in ${array}
   .do
      RVAL=$((RVAL + 1))
   .done
}



#
# r_add_unique_line <lines> <line>
#
#    Add <line> to <lines>, but ensures that this does not introduce a
#    new duplicate.
#
function r_add_unique_line()
{
   local lines="$1"
   local line="$2"

   if [ -z "${line:0:1}" -o -z "${lines:0:1}" ]
   then
      RVAL="${lines}${line}"
      return
   fi

   if find_line "${lines}" "${line}"
   then
      RVAL="${lines}"
      return
   fi

   RVAL="${lines}
${line}"
}


#
# r_remove_duplicate_separators_lines <lines>
#
#    Remove any duplicate strings in <lines>
#
function r_remove_duplicate_separators_lines()
{
   RVAL="`awk '!x[$0]++' <<< "$@"`"
}


#
# remove_duplicate_lines <lines> ...
#
#    Remove any duplicate strings in <lines>. Print result to stdout.
#
function remove_duplicate_lines()
{
   awk '!x[$0]++' <<< "$@"
}


#
# remove_duplicate_lines_stdin
#
#   Remove any duplicate strings in stdin. Print result to stdout.
#
function remove_duplicate_lines_stdin()
{
   awk '!x[$0]++'
}


#
# r_reverse_lines <lines>
#
#    Reverse the order of <lines>.
#    For very many lines use
#    `sed -n '1!G;h;$p' <<< "${lines}"`"
#
function r_reverse_lines()
{
   local lines="$1"

   local line
   local delim

   delim=""
   RVAL=

   while IFS=$'\n' read -r line
   do
      RVAL="${line}${delim}${RVAL}"
      delim=$'\n'
   done <<< "${lines}"
}


#
# r_split <string> [sep]
#
#    Parse substrings of <string> separated by <sep> into an array returned
#    as RVAL. The default separator is the contents of the IFS variable.
#
#    e.g. r_split "a,b,c" ","
#         printf "%s" "${RVAL[*]}"
#
function r_split()
{
   local s="$1"
   local sep="${2:-${IFS}}"

   if [ ${ZSH_VERSION+x} ]
   then
      unset RVAL
      RVAL=("${(@ps:$sep:)s}")
   else
      shell_disable_glob
      IFS="${sep}" read -r -a RVAL <<< "${s}"
      shell_enable_glob
   fi
}


#
# r_betwixt <sep> ...
#
#    Interpose a string between array elements to create a large string.
#
#    e.g. r_betwixt ',' a b c  -> "a,b,c"
#
function r_betwixt()
{
   local sep="$1" ; shift

   local tmp

   printf -v tmp "%s${sep}" "$@"
   RVAL="${tmp%"${sep}"}"
}

# ####################################################################
#                            Strings
# ####################################################################
#

#
# is_yes <s>
#
#    this non-localized variant detects 0/1 yes/no on/off y/n and
#    upper lowercase variante and returns 0 for YES, 1 for NO or empty
#    and 4 for all other values
#
is_yes()
{
   local s

   case "$1" in
      [yY][eE][sS]|[yY]|1|[oO][nN])
         return 0
      ;;
      [nN][oO]|[nN]|0|[oO][fF][fF]|"")
         return 1
      ;;

      *)
         return 4
      ;;
   esac
}


# ####################################################################
#                            Escape
# ####################################################################

#
# RESET
# NOCOLOR
#
#    "esape" functions prefer arbitarty strings for processing with the
#    external tools like `sed` or internal use in `eval`.
#
# SUBTITLE Conversion
# COLOR
#

#
# unused code
#

# escape_linefeeds()
# {
#    local text
#
#    text="${text//\|/\\\|}"
#    printf "%s" "${text}" | tr '\012' '|'
# }
#
#
# _unescape_linefeeds()
# {
#    tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
# }
#
#
# unescape_linefeeds()
# {
#    printf "%s\n" "$@" | tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
# }


#
# r_escaped_grep_pattern <s>
#
#    escape a string for use as a grep search pattern
#
#    this is heaps faster than the sed code. The loop method is way slower
#    then the substitution code, but ZSH is broken...
#
function r_escaped_grep_pattern()
{
   local s="$1"


   if [ ${ZSH_VERSION+x} ]
   then
      local i
      local c

      RVAL=
      for (( i=0; i < ${#s}; i++ ))
      do
         c="${s:$i:1}"
         case "$c" in
            $'\n'|$'\r'|$'\t'|$'\f'|"\\"|'['|']'|'$'|'*'|'.'|'^'|'|')
               RVAL+="\\"
            ;;
         esac
         RVAL+="$c"
      done
   else
      s="${s//\\/\\\\}"
      s="${s//\[/\\[}"
      s="${s//\]/\\]}"
   #   s="${s//\//\\/}"
      s="${s//\$/\\$}"
      s="${s//\*/\\*}"
      s="${s//\./\\.}"
      s="${s//\^/\\^}"
      s="${s//\|/\\|}"

      s="${s//$'\n'/\\$'\n'}"
      s="${s//$'\t'/\\$'\t'}"
      s="${s//$'\r'/\\$'\r'}"
      s="${s//$'\f'/\\$'\f'}"
      RVAL="$s"
   fi
}


#
# r_escaped_sed_pattern <s>
#
#    escape a string for use as a sed search pattern
#
#    assumed that / is used like in sed -e 's/x/y/'
#
function r_escaped_sed_pattern()
{
   local s="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      local i
      local c

      RVAL=
      for (( i=0; i < ${#s}; i++ ))
      do
         c="${s:$i:1}"
         case "$c" in
            $'\n'|$'\r'|$'\t'|$'\f'|"\\"|'['|']'|'/'|'$'|'*'|'.'|'^')
               RVAL+="\\"
            ;;
         esac
         RVAL+="$c"
      done
   else
      s="${s//\\/\\\\}"
      s="${s//\[/\\[}"
      s="${s//\]/\\]}"
      s="${s//\//\\/}"
      s="${s//\$/\\$}"
      s="${s//\*/\\*}"
      s="${s//\./\\.}"
      s="${s//\^/\\^}"
      s="${s//$'\n'/\\$'\n'}"
      s="${s//$'\t'/\\$'\t'}"
      s="${s//$'\r'/\\$'\r'}"
      s="${s//$'\f'/\\$'\f'}"
      RVAL="$s"
   fi
}


#
# r_escaped_sed_replacement <s>
#
#   escape a string for use as a sed replacement pattern
#
#   assumed that / is used like in sed -e 's/x/y/'
#
function r_escaped_sed_replacement()
{
   local s="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      local i
      local c

      RVAL=
      for (( i=0; i < ${#s}; i++ ))
      do
         c="${s:$i:1}"
         case "$c" in
            $'\n'|$'\r'|$'\t'|$'\f'|"\\"|'/'|'&')
               RVAL+="\\"
            ;;
         esac
         RVAL+="$c"
      done
   else
      s="${s//\\/\\\\}"        # escape backslashes first
      s="${s//\//\\/}"         # escape forward slashes
      s="${s//&/\\&}"          # escape ampersands

      s="${s//$'\n'/\\$'\n'}"
      s="${s//$'\t'/\\$'\t'}"
      s="${s//$'\r'/\\$'\r'}"
      s="${s//$'\f'/\\$'\f'}"
      RVAL="$s"
   fi
}


#
# r_escaped_spaces <s>
#
#    escape spaces in a string with "\ "
#
function r_escaped_spaces()
{
   RVAL="${1// /\\ }"
}


#
# r_escaped_backslashes <s>
#
#    escape backslashes in a string with "\\"
#
function r_escaped_backslashes()
{
   RVAL="${1//\\/\\\\}"
}


#
# r_escaped_singlequotes <s>
#
#    escape singlequotes in a string with '"'"'
#    which works nicely in shell scripts
#
#    it's assumed you want to put contents into
#    singlequotes e.g.
#      r_escaped_singlequotes "say 'hello'"
#      x='${RVAL}'
#
function r_escaped_singlequotes()
{
   local quote

   quote="'"
   RVAL="${1//${quote}/${quote}\"${quote}\"${quote}}"
}


#
# r_escaped_doublequotes <s>
#
#    escape " with \"
#    does not add surrounding ""
#
function r_escaped_doublequotes()
{
   RVAL="${*//\\/\\\\}"
   RVAL="${RVAL//\"/\\\"}"
}

#
# r_unescaped_doublequotes <s>
#
#    unescape \" to "
#
#    does not remove surrounding "" though
#
function r_unescaped_doublequotes()
{
   RVAL="${*//\\\"/\"}"
   RVAL="${RVAL//\\\\/\\}"
}


#
# r_escaped_shell_string <s>
#
#    escape a string for evaluation by the shell
#
function r_escaped_shell_string()
{
   printf -v RVAL '%q' "$*"
}


#
# r_escaped_json <s>
#
#    escape a string for JSON string content
#
function r_escaped_json()
{
   # Escape backslashes
   RVAL="${*//\\/\\\\}"

   # Escape double quotes
   RVAL="${RVAL//\"/\\\"}"

   # Escape newlines
   RVAL="${RVAL//$'\n'/\\n}"

   # Escape carriage returns
   RVAL="${RVAL//$'\r'/\\r}"

   # Escape tabs
   RVAL="${RVAL//$'\t'/\\t}"

   # Escape backspaces (not commonly needed, but included for completeness)
   RVAL="${RVAL//$'\b'/\\b}"

   # Escape form feeds (not commonly needed, but included for completeness)
   RVAL="${RVAL//$'\f'/\\f}"

   # Escape solidus (optional, but can be done)
   RVAL="${RVAL//\//\\/}"

   # Use sed to replace control characters with their Unicode escape sequences
   RVAL="${RVAL//$'\x1'/\\u0001}"
   RVAL="${RVAL//$'\x2'/\\u0002}"
   RVAL="${RVAL//$'\x3'/\\u0003}"
   RVAL="${RVAL//$'\x4'/\\u0004}"
   RVAL="${RVAL//$'\x5'/\\u0005}"
   RVAL="${RVAL//$'\x6'/\\u0006}"
   RVAL="${RVAL//$'\x7'/\\u0007}"
   # RVAL="${RVAL//$'\x8'/\\u0008}" "\t"
   # RVAL="${RVAL//$'\x9'/\\u0009}" "\b"
   # RVAL="${RVAL//$'\xA'/\\u000A}" "\n"
   RVAL="${RVAL//$'\xB'/\\u000B}"
   # RVAL="${RVAL//$'\xC'/\\u000C}" "\f"
   # RVAL="${RVAL//$'\xD'/\\u000D}" "\r"
   RVAL="${RVAL//$'\xE'/\\u000E}"
   RVAL="${RVAL//$'\xF'/\\u000F}"
   RVAL="${RVAL//$'\x10'/\\u0010}"
   RVAL="${RVAL//$'\x11'/\\u0011}"
   RVAL="${RVAL//$'\x12'/\\u0012}"
   RVAL="${RVAL//$'\x13'/\\u0013}"
   RVAL="${RVAL//$'\x14'/\\u0014}"
   RVAL="${RVAL//$'\x15'/\\u0015}"
   RVAL="${RVAL//$'\x16'/\\u0016}"
   RVAL="${RVAL//$'\x17'/\\u0017}"
   RVAL="${RVAL//$'\x18'/\\u0018}"
   RVAL="${RVAL//$'\x19'/\\u0019}"
   RVAL="${RVAL//$'\x1A'/\\u001A}"
   RVAL="${RVAL//$'\x1B'/\\u001B}"
   RVAL="${RVAL//$'\x1C'/\\u001C}"
   RVAL="${RVAL//$'\x1D'/\\u001D}"
   RVAL="${RVAL//$'\x1E'/\\u001E}"
   RVAL="${RVAL//$'\x1F'/\\u001F}"
}


# ####################################################################
#                          Prefix / Suffix
# ####################################################################
#
#
# RESET
# NOCOLOR
#
#    "fix" functions do simple string tests. One night argue, that use of these
#     functions makes shell scripts more readable.
#
# SUBTITLE Prefix/Suffix
# COLOR
#

#
# string_has_prefix <s> <prefix>
#
#    Check if <s> starts with <prefix>
#
#    Returns 0 if yes, 1 if NO
#
#    Example: if string_has_prefix "VfL Bochum" "VfL"
#             then
#                echo "as expected"
#             fi
function string_has_prefix()
{
  [ "${1#"$2"}" != "$1" ]
}


#
# string_has_suffix <s> <suffix>
#
#
#    Check if <s> starts with <suffix>
#
#    Returns 0 if yes, 1 if NO
#
#    Example: if string_has_suffix "VfL Bochum" "chum"
#             then
#                echo "as expected"
#             fi
function string_has_suffix()
{
  [ "${1%"$2"}" != "$1" ]
}


# ####################################################################
#                          Hash
# ####################################################################
#
#
# RESET
# NOCOLOR
#
#    Hash strings with the fnv1a 32 bit hash.
#
# SUBTITLE Hash
# COLOR
#

#
# get prefix leading up to character 'c', but if 'c' is quoted deal with it
# properly
#

#define MULLE_FNV1A_32_PRIME   0x01000193
#define MULLE_FNV1A_64_PRIME   0x0100000001b3ULL
#define MULLE_FNV1A_32_INIT    0x811c9dc5
#define MULLE_FNV1A_64_INIT    0xcbf29ce484222325ULL

#
# r_fnv1a_32 <s>
#
#    Creates a hash integer for string and passes it back in RVAL.
#    Example: r_fnv1a_32 "VfL Bochum 1848"
#             echo "${RVAL}"  # expect 738118884 (decimal)
#
function r_fnv1a_32()
{
   local i
   local len

   i=0
   len="${#1}"

   local hash
   local value

   hash=2166136261
   while [ $i -lt $len ]
   do
      printf -v value "%u" "'${1:$i:1}"
      hash=$(( ((hash ^ (value & 0xFF)) * 16777619) & 0xFFFFFFFF ))
      i=$(( i + 1 ))
   done

   RVAL=${hash}
}

# 64 bit, how can this be portably be written in shell script
# if the host is 32 bit ? investigate...



# ####################################################################
#                          Expansion
# ####################################################################
#
#
# RESET
# NOCOLOR
#
#    Expand variables like the shell into strings. e.g.
#    "username: ${USERNAME}" becomes "username: nat". The chief advantage over
#    shell `eval` is, that it is safer, as no commands are run such as they
#    would in: "username: `id`" for example.
#
# SUBTITLE Expansion
# COLOR
#

#
# get prefix leading up to character 'c', but if 'c' is quoted deal with it
# properly
#
_r_prefix_with_unquoted_string()
{
   local s="$1"
   local c="$2"

   local prefix
   local head
   local backslashes
   local before

   head=""
   while :
   do
      prefix="${s%%"${c}"*}"             # a${
      if [ "${prefix}" = "${s}" ]
      then
         RVAL="${head}${s}"
         return 1
      fi

      before="${prefix}"
      backslashes=0
      while [ ${#before} -gt 0 ] && [ "${before:$(( ${#before} - 1)):1}" = "\\" ]
      do
         backslashes=$((backslashes + 1))
         before="${before%?}"
      done

      if [ $((backslashes % 2)) -ne 0 ]
      then
         head="${head}${prefix}${c}"
         s="${s:$(( ${#prefix} + ${#c}))}"
         continue
      fi

      RVAL="${head}${prefix}"
      return 0
   done
}


#
# should be safe from malicious backticks and so forth, unfortunately
# this is not smart enough to parse all valid contents properly
#
_r_expand_string()
{
   local prefix_opener
   local prefix_closer
   local identifier
   local identifier_1
   local identifier_2
   local anything
   local value
   local default_value
   local head
   local found

   head=""

   # ex: "a${b:-c${d:-e}}g"
   while [ ${#_s} -ne 0 ]
   do
      # look for ${
      _r_prefix_with_unquoted_string "${_s}" '${'
      found=$?
      prefix_opener="${RVAL}" # can be empty

      if [ ${found} -ne 0 ]
      then
         case "${_s}" in
            *\\\${*)
               RVAL="${head}${prefix_opener}"
               return 0
            ;;
         esac
      fi

      #
      # if there is an } before hand, then we stop execution
      # but we consume that. If there is none at all we bail
      #
      if ! _r_prefix_with_unquoted_string "${_s}" '}'
      then
         if [ ${found} -eq 0 ]
         then
            log_error "missing '}'"
            RVAL=
            return 1
         fi

         #
         # if we don't have an opener ${ or it comes after us we
         # are done
         #
      else
         prefix_closer="${RVAL}"
         if [ ${found} -ne 0 ]
         then
            _s="${_s:${#prefix_closer}}"
            _s="${_s#\}}"
            RVAL="${head}${prefix_closer}"
            return 0
         fi

         if [ ${#prefix_closer} -lt ${#prefix_opener} ]
         then
            case "${prefix_opener}" in
               *\\\${*)
                  ;;
               *)
                  _s="${_s:${#prefix_closer}}"
                  _s="${_s#\}}"
                  RVAL="${head}${prefix_closer}"
                  return 0
               ;;
            esac
         fi
      fi

      #
      # No ${ here, then we are done
      #
      if [ ${found} -ne 0 ]
      then
         RVAL="${head}${_s}"
         return 0
      fi

      #
      # the middle is what we evaluate, that'_s whats left in '_s'
      #
      head="${head}${prefix_opener}"   # copy verbatim and continue

      _s="${_s:${#prefix_opener}}"
      _s="${_s#\$\{}"

      #
      # identifier_1 : ${identifier}
      # identifier_2 : ${identifier:-anything}
      #
      anything=
      identifier_1="${_s%%\}*}"     # this can't fail
      identifier_2="${_s%%:-*}"
      if [ "${identifier_2}" = "${_s}" ]
      then
         identifier_2=""
      fi

      default_value=
      if [ -z "${identifier_2}" -o ${#identifier_1} -lt ${#identifier_2} ]
      then
         identifier="${identifier_1}"
         _s="${_s:${#identifier}}"
         _s="${_s#\}}"
         anything=
      else
         identifier="${identifier_2}"
         _s="${_s:${#identifier}}"
         _s="${_s#:-}"
         anything="${_s}"
         if [ ! -z "${anything}" ]
         then
            if ! _r_expand_string
            then
               return 1
            fi
            default_value="${RVAL}"
         fi
      fi

      # idiot protection
      r_identifier "${identifier}"
      identifier="${RVAL}"

      if [ "${_expand}" = 'YES' ]
      then
         r_shell_indirect_expand "${identifier}"
         value="${RVAL:-${default_value}}"
      else
         value="${default_value}"
      fi
      head="${head}${value}"
   done

   RVAL="${head}"
   return 0
}


#
# r_expanded_string <s> [flag]
#
#    Expand variables of the form ${varname} contained in <s>. You can also add
#    a default value with ${varname:-default}. If flag is set to NO, only the
#    default value is used during expansion.
#    Example: year=1848 ; r_expanded_string "VfL Bochum ${year}"
#             echo "${RVAL}"  # expect "VfL Bochum 1848"
#
function r_expanded_string()
{
   local string="$1"
   local expand="${2:-YES}"

   local _s="${string}"
   local _expand="${expand}"

   local rval

   _r_expand_string
   rval=$?

   if [ $rval -eq 0 ]
   then
      RVAL="$(printf '%s' "${RVAL}" | sed 's/\\\${/${/g')"
   fi

   return $rval
}


fi
:
