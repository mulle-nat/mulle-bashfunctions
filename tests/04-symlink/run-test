#! /usr/bin/env bash


run_test_1()
{
   local result

   log_fluff "/usr/bin/sed relative"
   create_symlink "/usr/bin/sed" "deep/bin/sed1" "NO"
   log_fluff "`readlink deep/bin/sed1`"

   result="`echo "x" | ./deep/bin/sed1 's/x/y/g'`" || exit 1
   [ "${result}" = "y" ] || exit 1

   log_fluff "/usr/bin/sed absolute"
   create_symlink "/usr/bin/sed" "deep/bin/sed2" "YES"
   log_fluff "`readlink deep/bin/sed2`"

   result="`echo "x" | ./deep/bin/sed2 's/x/y/g'`" || exit 1
   [ "${result}" = "y" ] || exit 1

   linkpath="`symlink_relpath "/usr/bin/sed" "$PWD"`"

   log_fluff "${linkpath} absolute"
   create_symlink "${linkpath}" "deep/bin/sed3" "NO"
   log_fluff "`readlink deep/bin/sed3`"

   result="`echo "x" | ./deep/bin/sed3 's/x/y/g'`" || exit 1
   [ "${result}" = "y" ] || exit 1

   log_fluff "${linkpath} relative"
   create_symlink "${linkpath}" "deep/bin/sed4" "YES"
   log_fluff "`readlink deep/bin/sed4`"

   result="`echo "x" | ./deep/bin/sed4 's/x/y/g'`" || exit 1
   [ "${result}" = "y" ] || exit 1
}

main()
{
   _options_mini_main "$@"

   rm -rf deep 2> /dev/null

   run_test_1

   rm -rf deep 2> /dev/null

   log_info "----- ALL PASSED -----"
}


init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR:-../../src}"

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
}


init "$@"
main "$@"
