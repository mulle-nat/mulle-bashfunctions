# good: single line log_ calls
log_info "this is fine"
log_warning "just a warning"
log_verbose "ok"

# good: _log_ variants with continuation are fine (real functions)
_log_info "this is \
also fine"
_log_verbose "multi \
line ok"

# good: not a log_ call
some_log_info "not a log call \
really"
