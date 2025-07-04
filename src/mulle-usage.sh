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
if ! [ ${MULLE_USAGE_SH+x} ]
then
MULLE_USAGE_SH='included'

[ -z "${MULLE_BASHGLOBAL_SH}" ]    && _fatal "mulle-bashglobal.sh must be included before mulle-file.sh"
[ -z "${MULLE_COMPATIBILITY_SH}" ] && _fatal "mulle-compatibility.sh must be included before mulle-string.sh"


# RESET
# NOCOLOR
#
#    Functions to use instead of plain "cat" to produce usage information
#    for mulle-bashfunctions scripts.
#
#    Functions prefixed "r_" return the result in the global variable RVAL.
#    The return value 0 indicates success.
#
# TITLE INTRO
# COLOR



# ####################################################################
#                            Usage
# ####################################################################
#
# RESET
# NOCOLOR
#
#    Use usage_cat to reflow and output usage text.
#
# SUBTITLE Usage
# COLOR


#
# r_reflow_paragraph <text> [column_width] [indent]
#
#    Reflow a paragraph of text to fit within specified column width, breaking
#    only on word boundaries. Each output line is prefixed with the indent string.
#    The effective text width is column_width minus the length of the indent string.
#    The result is returned in the global variable RVAL.
#
#    Parameters:
#      text         - Text to reflow (required)
#      column_width - Total column width (default: 80)
#      indent       - String to prefix each line (default: "   ")
#
#    Example: r_reflow_paragraph 60 "    " "This is a very long paragraph that needs to be reflowed to fit within sixty columns total width."
#             echo "${RVAL}"
#             # Output:
#             #     This is a very long paragraph that needs to be
#             #     reflowed to fit within sixty columns total width.
#
r_reflow_paragraph()
{
   local text="$1"
   local column_width="${2:-80}"
   local indent="${3:-   }"

   local current_line=""
   local indent_length=${#indent}
   local result=""
   local width=$((column_width - indent_length - 1))  # Subtract 1 to avoid terminal wrapping
   local word

   RVAL=""

   # Split text into words
   for word in $text
   do
      # Check if adding this word would exceed width
      if [ ${#current_line} -eq 0 ]
      then
         current_line="$word"
      else
         if [ $((${#current_line} + ${#word} + 1)) -le $width ]
         then
            current_line="$current_line $word"
         else
            # Add current line to result and start new line
            if [ -n "$result" ]
            then
               result="$result"$'\n'"$indent$current_line"
            else
               result="$indent$current_line"
            fi
            current_line="$word"
         fi
      fi
   done

   # Add the last line if it's not empty
   if [ ${#current_line} -gt 0 ]
   then
      if [ -n "$result" ]
      then
         result="$result"$'\n'"$indent$current_line"
      else
         result="$indent$current_line"
      fi
   fi

   RVAL="$result"
}


#
# reflow_file [column_width] [indent]
#
#    Process a file line by line, reflowing paragraphs while preserving
#    non-paragraph lines. Paragraphs are detected as consecutive lines starting
#    with the specified indent string, terminated by empty lines or lines
#    without the required indentation.
#
#    Parameters:
#      column_width - Total column width (default: 80)
#      indent       - String that defines paragraph prefix (default: "   ")
#
#    Example: reflow_file 72 "    " < input.txt
#             # Reflows paragraphs in input.txt to 72 columns with 4-space indent
#
function reflow_file()
{
   local column_width="${1:-80}"
   local indent="${2:-   }"

   local min_indent_length=${#indent}
   local in_paragraph='NO'
   local line
   local paragraph_text=""
   local text_part

   while IFS= read -r line || [[ -n "$line" ]]
   do
      # Check if line starts with required number of spaces
      if [[ "$line" =~ ^[[:space:]]{${min_indent_length},} ]]
      then
         # Extract text after the leading spaces
         text_part=$(printf "%s" "$line" | sed 's/^[[:space:]]*//')

         if [ "$in_paragraph" = 'YES' ]
         then
            # Continue building paragraph
            paragraph_text="$paragraph_text $text_part"
         else
            # Start new paragraph
            in_paragraph='YES'
            paragraph_text="$text_part"
         fi
      else
         # Not a paragraph line
         if [ "$in_paragraph" = 'YES' ]
         then
            # End of paragraph - reflow and output
            r_reflow_paragraph "$paragraph_text" "$column_width" "$indent"
            printf "%s\n" "${RVAL}"
            in_paragraph='NO'
            paragraph_text=""
         fi

         # Output non-paragraph line as-is
         printf "%s\n" "$line"
      fi
   done

   # Handle case where file ends with a paragraph
   if [ "$in_paragraph" = 'YES' ]
   then
      r_reflow_paragraph "$paragraph_text" "$column_width" "$indent"
      printf "%s\n" "${RVAL}"
   fi
}


#
# usage_cat [min_width] [max_width]
#
#    Reflows the text to terminal width, but will fall back to 80, if it can't
#    be determined. Will by default not reflow to less than 40 or more than
#    120.
#
#    Example:
#      usage_cat <<< "text to output"
function usage_cat()
{
   local min_width="${1:-40}"
   local max_width="${2:-120}"

   local width

   width="${COLUMNS:-$(tput cols)}"
   if [ "$width" -gt "${max_width}" ]
   then
      width="${max_width}"
   fi
   if [ "$width" -lt "${min_width}" ]
   then
      width="${min_width}"
   fi

   reflow_file "${width}"
}


fi
:
