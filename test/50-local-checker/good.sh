#! /usr/bin/env bash
#
# This file must pass local-checker cleanly.
#

clean_function()
{
   local a
   local b
   local c="x"

   a="1"
   b="2"

   for i in 1 2 3
   do
      a="${a}${i}"
   done

   while [ -n "${b}" ]
   do
      b=""
   done
}


another_function()
{
   local a   # reusing name "a" is fine here: different function scope
   local x

   x="${a}"
}


# a local hoisted above a loop and merely assigned inside is fine
hoisted()
{
   local item
   local result

   for item in a b c
   do
      result="${result}${item}"
   done
}


# heredoc bodies are data, not code: prose containing the words "local",
# "do" and "done" must not be parsed as declarations
emits_prose()
{
   local text

   cat <<'EOF'
   synthesize the dominant local coding subareas that recur across docs
   for this topic, do not do the obvious thing, keep it done properly
   local terminology and local invariants matter
EOF

   text="done"
}


# nested functions have independent scopes: reusing "failed" in the outer
# function after an inner function also declared it is not a redeclaration
outer_with_nested()
{
   inner_helper()
   {
      local failed=0

      return ${failed}
   }

   local failed=0

   inner_helper || failed=1
}
