#! /usr/bin/env bash

set -e


fail()
{
   echo "failed:" "$@" "(got \"${result}\", expected \"${expect}\")" >&2
   exit 1
}


test_array()
{
    local array

    array="`array_insert "${array}" 0 "VfL"`"
    array="`array_insert "${array}" 1 "1848"`"
    array="`array_insert "${array}" 1 "Bochum"`"

    expect="VfL
Bochum
1848"
    [ "${array}" != "${expect}" ] && fail "test_array #1"

    array="`array_remove "${array}" "Bochum"`"

    expect="VfL
1848"
    [  "${array}" != "${expect}" ] && fail "test_array #2"

    :
}


test_assoc_array()
{
   local array

   array="`assoc_array_set "${array}" "1"  "Riemann"`"
   array="`assoc_array_set "${array}" "21" "Celozzi"`"
   array="`assoc_array_set "${array}" "2"  "Hoogland"`"
   array="`assoc_array_set "${array}" "5"  "Bastians"`"
   array="`assoc_array_set "${array}" "24" "Perthel"`"
   array="`assoc_array_set "${array}" "8"  "Losilla"`"
   array="`assoc_array_set "${array}" "39" "Steipermann"`"
   array="`assoc_array_set "${array}" "23" "Weilandt"`"
   array="`assoc_array_set "${array}" "10" "Eisfeld"`"
   array="`assoc_array_set "${array}" "22" "Stoeger"`"
   array="`assoc_array_set "${array}" "9"  "Wurtz"`"

   local result
   local expect

   result="`assoc_array_get "${array}" "10"`"
   expect="Eisfeld"
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #1 "

   array="`assoc_array_set "${array}" "10"`"
   result="`assoc_array_get "${array}" "10"`"
   expect=""
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #2"

   result="`assoc_array_get "${array}" "39"`"
   expect="Steipermann"
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #3"

   array="`assoc_array_set "${array}" "39" "Stiepermann"`"
   result="`assoc_array_get "${array}" "39"`"
   expect="Stiepermann"
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #4"

   :
}


main()
{
   _options_mini_main "$@"

   test_array
   test_assoc_array

   log_info "----- ALL PASSED -----"
}


init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR:-../../src}"

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
}


init "$@"
main "$@"


