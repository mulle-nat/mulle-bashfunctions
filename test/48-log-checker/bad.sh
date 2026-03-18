# bad: alias with continuation
log_info "this is \
bad"

# bad: log_verbose with continuation
log_verbose "line1 \
line2 \
line3"

# bad: log_debug with continuation
log_debug "some debug \
message"

# bad: multiline string literal (unclosed quote with embedded newline)
   [ -z "${DEPENDENCY_DIR}" ] && log_warning "DEPENDENCY_DIR is not set.
${C_INFO}This command must be run inside a mulle-sde virtual environment.
${C_RESET_BOLD}   mulle-sde craft"
