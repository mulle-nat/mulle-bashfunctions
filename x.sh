#! /usr/bin/env mulle-bash



log_checker()
{
   log_entry "log_checker" "$@"

            case "${tmp}" in
               *'"'*)
                  local left="${tmp%%'"'*}"
                  tmp="${tmp#*'"'}"
               ;;
            esac
}
