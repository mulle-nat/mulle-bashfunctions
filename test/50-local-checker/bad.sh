#! /usr/bin/env bash
#
# This file must be flagged by local-checker.
#

dup_function()
{
   local foo
   local bar

   foo="1"

   local foo   # POISON: redeclared in same function
}


loop_for()
{
   local result

   for i in 1 2 3
   do
      local tmp   # POISON: local inside for-loop
      tmp="${i}"
      result="${result}${tmp}"
   done
}


loop_while()
{
   local n=0

   while [ "${n}" -lt 10 ]
   do
      local step   # POISON: local inside while-loop
      step=1
      n=$((n + step))
   done
}
