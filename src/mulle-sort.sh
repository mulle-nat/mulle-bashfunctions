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


declare -g ascending=1
declare -g descending=255


default_sort_compare()
{
   if [[ "$1" > "$2" ]]
   then
      return $descending
   fi

   [[ "$1" = "$2" ]]
   return $?
}


#
# r_qsort "$@"
#
#    Sorts incoming elements or array with either the "default_sort_compare"
#    function (which is predefined) or the "SORT_COMPARE_FUNCTION" given
#    as a environment/global variable. The compare function is of the form
#    compare <a> <b>. Return either $descending or $ascending or 0.
#
#    e.g.
#    local a=( 3 2 1)
#    local RVAL=()
#
#    r_qsort "${a[@]}"
#    printf "%s\n" "${RVAL[*]}"
#
function r_qsort()
{
   #
   # stolen from
   # https://stackoverflow.com/questions/7442417/how-to-sort-an-array-in-bash
   #

   RVAL=()
   (($#==0)) && return 0

   if [ ${ZSH_VERSION+x} ]
   then
      setopt local_options KSH_ARRAYS
   fi

   local pivot="$1"
   shift

   local i
   local smaller=()
   local larger=()

   local rval

   for i in "$@"
   do
      ${SORT_COMPARE_FUNCTION:-default_sort_compare} "$i" "$pivot"
      rval=$?

      if [ $rval -eq $ascending ]
      then
         smaller+=( "$i" )
      else
         larger+=( "$i" )
      fi
   done

   r_qsort "${smaller[@]}"
   smaller=( "${RVAL[@]}" )

   r_qsort "${larger[@]}"
   larger=( "${RVAL[@]}" )

   RVAL=( "${smaller[@]}" "$pivot" "${larger[@]}" )

   # log_setting "RVAL: ${RVAL[*]}"
}




#
# r_mergesort "$@"
#
#    Sorts incoming elements or array with either the "default_sort_compare"
#    function (which is predefined) or the "SORT_COMPARE_FUNCTION" given
#    as a environment/global variable. The compare function is of the form
#    compare <a> <b>. Return either $descending or $ascending or 0.
#
#    e.g.
#    local a=( 3 2 1)
#    local RVAL=()
#
#    r_mergesort "${a[@]}"
#    printf "%s\n" "${RVAL[*]}"
#
function r_mergesort()
{
   local n


   # coded mahself ...
   #   0  1  2  3  4
   # ( d, b, a, e, c) : n=5
   #  \----/ |        : m=2 (n/2)
   #         \------/ : o=3 (n-m)
   n=$#

   if [ $n -le 1 ]
   then
      RVAL=( "$@" )
      return
   fi

   if [ ${ZSH_VERSION+x} ]
   then
      setopt local_options KSH_ARRAYS
   fi

   local m
   local o

   m=$(( n / 2 ))
   o=$(( n - m))

   local in=( "$@" )
   local smaller

   r_mergesort "${in[@]:0:$m}"
   smaller=( "${RVAL[@]}" )

   local larger

   r_mergesort "${in[@]:$m:$o}"
   larger=( "${RVAL[@]}" )

   # log_setting "m: $m"
   # log_setting "n: $n"
   # log_setting "o: $o"
   # log_setting "smaller: ${smaller[*]}"
   # log_setting "larger: ${larger[*]}"

   # merge

   local i
   local j

   i=0
   j=0
   RVAL=()

   while :
   do
      # is a bottom element left ?
      if [ $i -lt $m ]
      then
         # if no top element left its easy
         if [ $j -ge $o ]
         then
            RVAL+=( "${smaller[$i]}" )
            i=$((i + 1))
            continue
         fi

         ${SORT_COMPARE_FUNCTION:-default_sort_compare} "${smaller[$i]}" "${larger[$j]}"
         rval=$?

         if [ $rval -eq $ascending ]
         then
            RVAL+=( "${smaller[$i]}" )
            i=$((i + 1))
            continue
         fi

         RVAL+=( "${larger[$j]}" )
         j=$((j + 1))
         continue
      fi

      if [ $j -ge $o ]
      then
         break
      fi

      RVAL+=( "${larger[$j]}" )
      j=$((j + 1))
   done

   # log_setting "RVAL: ${RVAL[*]}"
}


# #
# # retarded bubblesort
# #
# r_bubblesort()
# {
#    log_entry r_bubblesort "$@"
#
#    local n=$#
#
#    RVAL=( "$@" )
#    if [ $n -le 1 ]
#    then
#       return
#    fi
#
#    local i
#    local i_1
#    local j
#    local n_2
#    local in
#
#    local a
#    local b
#    local swap
#
#    n_1=$((n - 1))
#
#    #  c b a       n = 3
#    #              n_2 = 1
#    #  b c a
#    #  b a c
#
#    j=$n_1
#    while :
#    do
#       in=( ${RVAL[@]} )
#       RVAL=()
#
#       i=0
#       b="${in[@]:$i:1}"
#       while [ $i -lt $j ]
#       do
#          a=$b
#          i_1=$((i + 1))
#          b="${in[@]:$i_1:1}"
#
#          ${SORT_COMPARE_FUNCTION:-default_sort_compare} "${a}" "${b}"
#          rval=$?
#
#          if [ $rval -eq $descending ]
#          then
#             RVAL+=( "${b}" )
#             b="$a"
#          else
#             RVAL+=( "${a}" )
#          fi
#          i=$i_1
#       done
#
#       RVAL+=( "${b}" )
#       if [ $j -lt $n_1 ]
#       then
#          RVAL+=( "${in[@]:$((j + 1)):$((n_1 - j))}" )
#       fi
#
#       echo "${RVAL[*]}"
#
#       [ "${#RVAL[@]}" -eq $n ] || _internal_fail "too few elements"
#
#       j=$((j - 1))
#
#       if [ $j -eq 0 ]
#       then
#          break
#       fi
#    done
#
#    log_setting "RVAL: ${RVAL[*]}"
# }
#