# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
#
# Prelude to be placed at top of each script. Rerun this script either in
# bash or zsh, if not already running in either (which can happen!)
# Allows script to run on systems that either have bash (linux) or
# zsh (macOS) only by default.
#


mulle_isbase64_char()
{
   [ -z "${1//[A-Za-z0-9\/+]/}" ]
}


r_mulle_base64_encode_string()
{
   local width="$1"
   local _src="$2"

   _src="${_src}"$'\n'     # stay compatible

   local inLen="${#_src}"
   local inPos=0
   local breakPos=0
   local out
   local c1
   local c2
   local c3
   local d1
   local d2
   local d3
   local d4
   local i
   local n
   local index

   local mulle_base64tab_string="\
ABCDEFGHIJKLMNOPQRSTUVWXYZ\
abcdefghijklmnopqrstuvwxyz0123456789+/"

   breakPos=${width}

   n=$(( inLen / 3 ))
   remain=$(( inLen % 0x3 ))

   i=0
   while [ $i -lt $n ]
   do
      printf -v c1 "%d" "'${_src:${inPos}:1}"
      inPos=$(( inPos + 1 ))
      printf -v c2 "%d" "'${_src:${inPos}:1}"
      inPos=$(( inPos + 1 ))
      printf -v c3 "%d" "'${_src:${inPos}:1}"
      inPos=$(( inPos + 1 ))

      index=$(( c1 >> 2 ))
      d1="${mulle_base64tab_string:${index}:1}"
      index=$(( ((c1 & 0x03) << 4) | (c2 >> 4) ))
      d2="${mulle_base64tab_string:${index}:1}"
      index=$(( ((c2 & 0x0F) << 2) | ((c3 & 0xC0) >> 6) ))
      d3="${mulle_base64tab_string:${index}:1}"
      index=$(( c3 & 0x3F ))
      d4="${mulle_base64tab_string:${index}:1}"

      out="${out}${d1}${d2}${d3}${d4}"
      outPos=$(( outPos + 4 ))

      if [ "${width}" -gt 0  -a ${outPos} -ge ${breakPos} ]
      then
         out="${out}"$'\n'
         outPos=$(( outPos + 1 ))
         breakPos=$(( outPos + $width ))
      fi
      i=$(( i + 1))
   done

   case $remain in
      2)
         printf -v c1 "%d" "'${_src:${inPos}:1}"
         inPos=$(( inPos + 1 ))
         printf -v c2 "%d" "'${_src:${inPos}:1}"

         index=$(( (c1 & 0xFC) >> 2 ))
         d1="${mulle_base64tab_string:${index}:1}"
         index=$(( ((c1 & 0x03) << 4) | ((c2 & 0xF0) >> 4) ))
         d2="${mulle_base64tab_string:${index}:1}"
         index=$(( ((c2 & 0x0F) << 2) ))
         d3="${mulle_base64tab_string:${index}:1}"

         out="${out}${d1}${d2}${d3}="
      ;;

      1)
         printf -v c1 "%d" "'${_src:${inPos}:1}"
         index=$(( (c1 & 0xFC) >> 2 ))
         d1="${mulle_base64tab_string:${index}:1}"
         index=$(( (c1 & 0x03) << 4 ))
         d2="${mulle_base64tab_string:${index}:1}"
         out="${out}${d1}${d2}=="
      ;;

      0)
      ;;
   esac

   RVAL="${out}"
}


mulle_base64_encode()
{
   local width="$1"
   local filename="${2:--}"

   local _src

   if [ "${filename}" = '-' ]
   then
      _src="`cat`" || return 1
   else
      _src="`cat "${filename}"`" || return 1
   fi

   if ! r_mulle_base64_encode_string "${width}" "${_src}"
   then
      return 1
   fi

   printf "%s\n" "${RVAL}"
}


mulle_base64idx_string=\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\076\377\377\377\077'\
$'\064\065\066\067\070\071\072\073'\
$'\074\075\377\377\377\377\377\377'\
$'\377'_$'\001\002\003\004\005\006'\
$'\007\010\011\012\013\014\015\016'\
$'\017\020\021\022\023\024\025\026'\
$'\027\030\031\377\377\377\377\377'\
$'\377\032\033\034\035\036\037\040'\
$'\041\042\043\044\045\046\047\050'\
$'\051\052\053\054\055\056\057\060'\
$'\061\062\063\377\377\377\377\377'


r_mulle_base64_decode_char()
{
   local c="$1"

   if [ "$c" -eq 65 ]
   then
      RVAL=0
      return
   fi
   printf -v RVAL "%d" "'${mulle_base64idx_string:${c}:1}"
}


r_mulle_base64_decode_string()
{
   local _src="$1"

   local isErr=0
   local isEndSeen=0
   local b1
   local b2
   local b3
   local a1
   local a2
   local a3
   local a4
   local inPos=0
   local outPos=0
   local inLen
   local c
   local out

   # can' encode \0 here at
#   log_debug "%d: \"%s\"" "${#mulle_base64idx_string}" "${mulle_base64idx_string}"
#
#   sep=","
#   i=0
#   j=2
#   while [ $i -lt 128 ]
#   do
#      printf "%02x%s" "'${mulle_base64idx_string:${i}:1}" "$sep"
#      sep=","
#
#      if [ $j -eq 8 ]
#      then
#         sep=$'\n'
#         j=0
#      fi
#
#      i=$((i + 1))
#      j=$((j + 1))
#   done

   inLen="${#_src}"

   #
   # Started as aiteral translation of original crap C code.
   #
   # Get four input chars at a time and decode them. Ignore white space
   # chars (CR, LF, SP, HT). If '=' is encountered, terminate input. If
   # a char other than white space, base64 char, or '=' is encountered,
   # flag an input error, but otherwise ignore the char.
   #
   while [ $inPos -lt $inLen ]
   do
      for i in 1 2 3 4
      do
         while [ $inPos -lt $inLen ]
         do
            c="${_src:${inPos}:1}"
            inPos=$(( inPos + 1 ))

            if mulle_isbase64_char "${c}"
            then
               printf -v "a${i}" "${c}"
               break
            fi

            case "${c}" in
               '=')
                  printf -v "a${i}" "0"
                  isEndSeen=1
                  break
               ;;

               $'\r'|$'\n'|' '|$'\t')
               ;;

               *)
                  log_error "garbage character ${c} in base64 string"
                  RVAL=
                  return 1
               ;;
            esac
         done

         if [ $isEndSeen -ne 0 ]
         then
            i=$((i - 1))
            break
         fi
      done

      case "${i}" in
         4)
            printf -v a1 "%d" "'${a1}"
            printf -v a2 "%d" "'${a2}"
            printf -v a3 "%d" "'${a3}"
            printf -v a4 "%d" "'${a4}"

            r_mulle_base64_decode_char "$a1"
            a1=${RVAL}
            r_mulle_base64_decode_char "$a2"
            a2=${RVAL}
            r_mulle_base64_decode_char "$a3"
            a3=${RVAL}
            r_mulle_base64_decode_char "$a4"
            a4=${RVAL}

            b1=$(( ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03) ))
            b2=$(( ((a2 << 4) & 0xF0) | ((a3 >> 2) & 0x0F) ))
            b3=$(( ((a3 << 6) & 0xC0) | ( a4     & 0x3F) ))

            printf -v b1 \\$(printf '%03o' $b1)
            printf -v b2 \\$(printf '%03o' $b2)
            printf -v b3 \\$(printf '%03o' $b3)

            out="${out}${b1}${b2}${b3}"
         ;;

         3)
            printf -v a1 "%d" "'${a1}"
            printf -v a2 "%d" "'${a2}"
            printf -v a3 "%d" "'${a3}"

            r_mulle_base64_decode_char "$a1"
            a1=${RVAL}
            r_mulle_base64_decode_char "$a2"
            a2=${RVAL}
            r_mulle_base64_decode_char "$a3"
            a3=${RVAL}

            b1=$(( ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03) ))
            b2=$(( ((a2 << 4) & 0xF0) | ((a3 >> 2) & 0x0F) ))

            printf -v b1 \\$(printf '%03o' $b1)
            printf -v b2 \\$(printf '%03o' $b2)

            out="${out}${b1}${b2}"
         ;;

         2)
            printf -v a1 "%d" "'${a1}"
            printf -v a2 "%d" "'${a2}"

            r_mulle_base64_decode_char "$a1"
            a1=${RVAL}
            r_mulle_base64_decode_char "$a2"
            a2=${RVAL}

            b1=$(( ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03) ))

            printf -v b1 \\$(printf '%03o' $b1)

            out="${out}${b1}"
         ;;

         *)
            if [ "${ignore_garbage}" = 'YES' ]
            then
               continue
            fi

            log_error "garbage character in base64 string"
            RVAL=
            return 1
         ;;
      esac

      if [ $isEndSeen -eq 1 ]
      then
         break
      fi
   done

   RVAL="${out%$'\n'}"
   return 0
}


mulle_base64_decode()
{
   local filename="${1:--}"

   local _src

   if [ "${filename}" = '-' ]
   then
      _src="`cat`" || return 1
   else
      _src="`cat "${filename}"`" || return 1
   fi

   if ! r_mulle_base64_decode_string "${_src}"
   then
      return 1
   fi

   printf "%s\n" "${RVAL}"
}


#
# mulle_base64 [options] [input]
#
#   The point of this function is to act the same as `base64` would do.
#   But you don't need to have base64 installed and this function abstracts
#   some platform differences away.
#
# Options:
#   -d         : decode
#   -i         : ignore garbage during decode, not recommended
#   -w <width> : width for encoding (74)
#
mulle_base64()
{
   local decode
   local ignore
   local width=76

   while [ $# -ne 0 ]
   do
      case "$1" in
         -d|--decode)
            decode='YES'
         ;;

         -i)
            ignore_garbage='YES'
         ;;

         -w|--width|-b)
            shift
            width="$1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case "${MULLE_UNAME}" in
      openbsd|netbsd)
         # those base64 encoder suck, ignore
      ;;

      *)
         local base64

         if base64="`command -v base64`"
         then
            if [ "${decode}" = 'YES' ]
            then
               rexekutor "${base64}" -d "$@"
               return $?
            fi

            case "${MULLE_UNAME}" in
               openbsd)
                  rexekutor "${base64}" "$@"
                  return $?
               ;;

               macos|*bsd|dragonfly)
                  rexekutor "${base64}" -b "${width}" "$@"
                  return $?
               ;;
            esac

            rexekutor "${base64}" -w "${width}"
            return $?
         fi
      ;;
   esac

   if [ "${decode}" ]
   then
      mulle_base64_decode "${ignore_garbage}" "$@"
      return $?
   fi

   mulle_base64_encode "${width}" "$@"
}