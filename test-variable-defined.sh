#! /bin/sh
#
# Test shell_is_variable_defined and shell_is_variable_undefined_or_empty
# Run with: bash test-variable-defined.sh && zsh test-variable-defined.sh
#

MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions libexec-dir`" || exit 1
. "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-boot.sh" || exit 1
. "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

ERRORS=0

expect_true()
{
   if "$@"
   then
      :
   else
      printf "FAIL: expected true: %s\n" "$*" >&2
      ERRORS=$(( ERRORS + 1 ))
   fi
}

expect_false()
{
   if "$@"
   then
      printf "FAIL: expected false: %s\n" "$*" >&2
      ERRORS=$(( ERRORS + 1 ))
   fi
}

# --- shell_is_variable_defined ---

# undefined variable
unset UNDEFINED_VAR
expect_false shell_is_variable_defined UNDEFINED_VAR

# defined but empty
EMPTY_VAR=""
export EMPTY_VAR
expect_true shell_is_variable_defined EMPTY_VAR

# defined with value
VALUED_VAR="hello"
export VALUED_VAR
expect_true shell_is_variable_defined VALUED_VAR

# --- shell_is_variable_undefined_or_empty ---

# undefined variable
unset UNDEFINED_VAR
expect_true shell_is_variable_undefined_or_empty UNDEFINED_VAR

# defined but empty
expect_true shell_is_variable_undefined_or_empty EMPTY_VAR

# defined with value
expect_false shell_is_variable_undefined_or_empty VALUED_VAR

# --- edge case: variable set to "0" is defined and not empty ---
ZERO_VAR="0"
export ZERO_VAR
expect_true shell_is_variable_defined ZERO_VAR
expect_false shell_is_variable_undefined_or_empty ZERO_VAR

if [ ${ERRORS} -eq 0 ]
then
   printf "ALL PASSED (%s)\n" "${ZSH_VERSION:-bash}"
else
   printf "%d FAILED (%s)\n" "${ERRORS}" "${ZSH_VERSION:-bash}" >&2
   exit 1
fi
