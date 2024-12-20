cmake_minimum_required (VERSION 3.13)

project( mulle-bashfunctions VERSION 6.5.1 LANGUAGES NONE)


#
# in order to boost initial _init speed concatenate all files that
# are typically loaded together into processed headers. It would be nice to
# minify those but there is nothing good out there, which doesn't corrupt
# shell code. The only minification we can get in a bash script is
# stripping off comments and whitespace though.
#
# cat <<EOF
#  'whatever   # foo
# EOF
#
set( NONE_SCRIPTS
"src/mulle-bashglobal.sh"
"src/mulle-bashloader.sh"
"src/mulle-compatibility.sh"
)
string( REPLACE ";" " " NONE_SCRIPTS_STR "${NONE_SCRIPTS}")


set( MINIMAL_ADDITIONAL_SCRIPTS
"src/mulle-logging.sh"
"src/mulle-exekutor.sh"
"src/mulle-string.sh"
"src/mulle-init.sh"
"src/mulle-options.sh"
)

set( MINIMAL_SCRIPTS
${NONE_SCRIPTS}
${MINIMAL_ADDITIONAL_SCRIPTS}
)
string( REPLACE ";" " " MINIMAL_SCRIPTS_STR "${MINIMAL_SCRIPTS}")


set( DEFAULT_ADDITIONAL_SCRIPTS
"src/mulle-path.sh"
"src/mulle-file.sh"
)


set( DEFAULT_SCRIPTS
${MINIMAL_SCRIPTS}
${DEFAULT_ADDITIONAL_SCRIPTS}
)
string( REPLACE ";" " " DEFAULT_SCRIPTS_STR "${DEFAULT_SCRIPTS}")


set( ALL_ADDITIONAL_SCRIPTS
"src/mulle-array.sh"
"src/mulle-base64.sh"
"src/mulle-case.sh"
"src/mulle-etc.sh"
"src/mulle-parallel.sh"
"src/mulle-sort.sh"
"src/mulle-url.sh"
"src/mulle-version.sh"
)

set( ALL_SCRIPTS
${DEFAULT_SCRIPTS}
${ALL_ADDITIONAL_SCRIPTS}
)
string( REPLACE ";" " " ALL_SCRIPTS_STR "${ALL_SCRIPTS}")


set( MINIMAL_EMBED_SCRIPTS
"src/mulle-bashglobal.sh"
"src/mulle-compatibility.sh"
${MINIMAL_ADDITIONAL_SCRIPTS}
)

set( DEFAULT_EMBED_SCRIPTS
"src/mulle-bashglobal.sh"
"src/mulle-compatibility.sh"
${MINIMAL_ADDITIONAL_SCRIPTS}
${DEFAULT_ADDITIONAL_SCRIPTS}
)

set( ALL_EMBED_SCRIPTS
"src/mulle-bashglobal.sh"
"src/mulle-compatibility.sh"
${MINIMAL_ADDITIONAL_SCRIPTS}
${DEFAULT_ADDITIONAL_SCRIPTS}
${ALL_ADDITIONAL_SCRIPTS}
)


string( REPLACE ";" " " DEFAULT_EMBED_SCRIPTS_STR "${DEFAULT_EMBED_SCRIPTS}")

execute_process( COMMAND bash -c "[ ! -f \"src/mulle-bashfunctions-embed.sh\" ] || chmod a+w \"src/mulle-bashfunctions-embed.sh\""
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
execute_process( COMMAND bash -c "cat src/embed-header.sh ; grep -E -h -v \"^#|^\ *#\" ${DEFAULT_EMBED_SCRIPTS_STR}; cat src/embed-footer.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-embed.sh")
execute_process( COMMAND chmod a-w "src/mulle-bashfunctions-embed.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")


string( REPLACE ";" " " MINIMAL_EMBED_SCRIPTS_STR "${MINIMAL_EMBED_SCRIPTS}")


execute_process( COMMAND bash -c "[ ! -f \"src/mulle-bashfunctions-minimal-embed.sh\" ] || chmod a+w \"src/mulle-bashfunctions-minimal-embed.sh\""
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
execute_process( COMMAND bash -c "cat src/embed-minimal-header.sh ; grep -E -h -v \"^#|^\ *#\" ${MINIMAL_EMBED_SCRIPTS_STR}; cat src/embed-minimal-footer.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-minimal-embed.sh")
execute_process( COMMAND chmod a-w "src/mulle-bashfunctions-minimal-embed.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")


string( REPLACE ";" " " ALL_EMBED_SCRIPTS_STR "${ALL_EMBED_SCRIPTS}")

execute_process( COMMAND bash -c "[ ! -f \"src/mulle-bashfunctions-all-embed.sh\" ] || chmod a+w \"src/mulle-bashfunctions-all-embed.sh\""
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
execute_process( COMMAND bash -c "cat src/embed-all-header.sh ; grep -E -h -v \"^#|^\ *#\" ${ALL_EMBED_SCRIPTS_STR}; cat src/embed-all-footer.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-all-embed.sh")
execute_process( COMMAND chmod a-w "src/mulle-bashfunctions-all-embed.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")


# probably more of a fun thing:
# 
# embed using eval `base64 <<< "<data>" | gzip -d -c`
# execute_process( COMMAND bash "-c" "gzip -c -9 \"src/mulle-bashfunctions-embed.sh\" | base64 \"src/mulle-bashfunctions-embed.sh.gz.base64\"" 
#                  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
#                  INPUT_FILE "src/mulle-bashfunctions-embed.sh"
#                  OUTPUT_FILE "src/mulle-bashfunctions-embed.sh.gz.base64")

execute_process( COMMAND bash -c "[ ! -f \"src/mulle-bashfunctions-none.sh\" ] || chmod a+w \"src/mulle-bashfunctions-none.sh\""
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
execute_process( COMMAND bash -c "cat src/header.sh ; grep -E -h -v \"^#|^\ *#\" ${NONE_SCRIPTS_STR}"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-none.sh")
execute_process( COMMAND chmod a-w "src/mulle-bashfunctions-none.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

execute_process( COMMAND bash -c "[ ! -f \"src/mulle-bashfunctions.sh\" ] || chmod a+w \"src/mulle-bashfunctions.sh\""
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
execute_process( COMMAND bash -c "cat src/header.sh ; grep -E -h -v \"^#|^\ *#\" ${DEFAULT_SCRIPTS_STR}"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions.sh")
execute_process( COMMAND chmod a-w "src/mulle-bashfunctions.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

execute_process( COMMAND bash -c "[ ! -f \"src/mulle-bashfunctions-minimal.sh\" ] || chmod a+w \"src/mulle-bashfunctions-minimal.sh\""
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
execute_process( COMMAND bash -c "cat src/header.sh ; grep -E -h -v \"^#|^\ *#\" ${MINIMAL_SCRIPTS_STR}"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-minimal.sh")
execute_process( COMMAND chmod a-w "src/mulle-bashfunctions-minimal.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

execute_process( COMMAND bash -c "[ ! -f \"src/mulle-bashfunctions-all.sh\" ] || chmod a+w \"src/mulle-bashfunctions-all.sh\""
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
execute_process( COMMAND bash -c "cat src/header.sh ; grep -E -h -v \"^#|^\ *#\" ${ALL_SCRIPTS_STR}"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-all.sh")
execute_process( COMMAND chmod a-w "src/mulle-bashfunctions-all.sh"
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")


set( SCRIPTS
mulle-bash
mulle-bashfunctions
)


set( MULLE_SDE_EXTENSION_DIRS
   "src/mulle-nat/file.sh"
)


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
)


#
# Install
#
execute_process( COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/mulle-bashfunctions" version
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_BASHFUNCTIONS_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_BASHFUNCTIONS_VERSION is ${MULLE_BASHFUNCTIONS_VERSION} according to mulle-bashfunctions")


set( PROJECT_VERSION "${MULLE_BASHFUNCTIONS_VERSION}")


message( STATUS "SCRIPTS is ${SCRIPTS}")
message( STATUS "LIBRARY_SCRIPTS is ${LIBRARY_SCRIPTS}")
message( STATUS "MULLE_SDE_EXTENSION_DIRS is ${MULLE_SDE_EXTENSION_DIRS}")



install( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


install( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-bashfunctions/${PROJECT_VERSION}")


install( DIRECTORY ${MULLE_SDE_EXTENSION_DIRS}
DESTINATION "share/mulle-sde/extensions/mulle-nat"
USE_SOURCE_PERMISSIONS
PATTERN "*._DS_Store" EXCLUDE)


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
