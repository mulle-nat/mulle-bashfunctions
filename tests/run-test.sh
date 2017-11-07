#! /bin/sh


TEST_DIR="`dirname "$0"`"
PROJECT_DIR="$( cd "${TEST_DIR}/.." ; pwd -P)"

MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR:-../../src}"
export MULLE_BASHFUNCTIONS_LIBEXEC_DIR

main()
{
   local i

   for i in "${TEST_DIR}"/*
   do
      if [ -x "$i/run-test.sh" ]
      then
         echo "------------------------------------------" >&2
         echo "$i:" >&2
         echo "------------------------------------------" >&2
         ( cd "$i" && ./run-test.sh "$@" ) || exit 1
      fi
   done
}

main "$@"
