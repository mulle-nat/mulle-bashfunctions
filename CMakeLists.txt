cmake_minimum_required (VERSION 3.13)

project( mulle-bashfunctions NONE)


#
# in order to boost initial _init speed concatenate all files that
# are typically loaded together into processed headers. It would be nice to
# minify those but there is nothing good out there, which doesn't corrupt
# shell code like. The only minification we can get in a bash script is
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


set( MINIMAL_SCRIPTS
${NONE_SCRIPTS}
"src/mulle-logging.sh"
"src/mulle-exekutor.sh"
"src/mulle-string.sh"
"src/mulle-init.sh"
"src/mulle-options.sh"
)

set( DEFAULT_SCRIPTS
${MINIMAL_SCRIPTS}
"src/mulle-path.sh"
"src/mulle-file.sh"
)

set( ALL_SCRIPTS
${DEFAULT_SCRIPTS}
"src/mulle-array.sh"
"src/mulle-case.sh"
"src/mulle-parallel.sh"
"src/mulle-version.sh"
"src/mulle-etc.sh"
)


set( EMBED_SCRIPTS
"src/mulle-bashglobal.sh"
"src/mulle-compatibility.sh"
"src/mulle-logging.sh"
"src/mulle-exekutor.sh"
"src/mulle-string.sh"
"src/mulle-init.sh"
"src/mulle-options.sh"
"src/mulle-path.sh"
"src/mulle-file.sh"
"src/mulle-array.sh"
"src/mulle-case.sh"
"src/mulle-parallel.sh"
"src/mulle-version.sh"
"src/mulle-etc.sh"
)

execute_process( COMMAND egrep -h -v "^#|^\ *#" ${EMBED_SCRIPTS}
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-embed.sh")

# probably more of a fun thing:
# embed using eval `base64 <<< "<data>" | gzip -d -c`
execute_process( COMMAND bash "-c" "gzip -c -9 \"src/mulle-bashfunctions-embed.sh\" | base64 -b 79 -o \"src/mulle-bashfunctions-embed.gz.base64\"" 
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 INPUT_FILE "src/mulle-bashfunctions-embed.sh"
                 OUTPUT_FILE "src/mulle-bashfunctions-embed.sh.gz.base64")

execute_process( COMMAND cat ${NONE_SCRIPTS}
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-none.sh")

execute_process( COMMAND cat ${DEFAULT_SCRIPTS}
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions.sh")

execute_process( COMMAND cat ${MINIMAL_SCRIPTS}
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-minimal.sh")

execute_process( COMMAND cat ${ALL_SCRIPTS}
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_FILE "src/mulle-bashfunctions-all.sh")


set( SCRIPTS
mulle-bashfunctions-env
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
execute_process( COMMAND "${PROJECT_SOURCE_DIR}/mulle-bashfunctions-env" version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_BASHFUNCTIONS_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_BASHFUNCTIONS_VERSION is ${MULLE_BASHFUNCTIONS_VERSION} according to mulle-bashfunctions-env")


set( PROJECT_VERSION "${MULLE_BASHFUNCTIONS_VERSION}")



INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-bashfunctions/${PROJECT_VERSION}")


INSTALL( FILES ${TEMPLATE_FILE}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "share/mulle-bashfunctions/${PROJECT_VERSION}")


INSTALL( DIRECTORY ${MULLE_SDE_EXTENSION_DIRS}
DESTINATION "share/mulle-sde/mulle-nat"
USE_SOURCE_PERMISSIONS
PATTERN "*._DS_Store" EXCLUDE)


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.txt)
include( CPack)

