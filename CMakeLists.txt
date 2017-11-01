cmake_minimum_required (VERSION 3.0)

# use C, because otherwise a CXX compiler is required
project( mulle-bashfunctions C)



execute_process( COMMAND ./mulle-bashfunctions-env
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_BASHFUNCTIONS_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_BASHFUNCTIONS_VERSION is ${MULLE_BASHFUNCTIONS_VERSION} according to mulle-bashfunctions-env")


set( PROJECT_VERSION "${MULLE_BASHFUNCTIONS_VERSION}")


set( SCRIPTS
mulle-bashfunctions-env
)


set( LIBRARY_SCRIPTS
mulle-array.sh
mulle-bashfunctions.sh
mulle-exekutor.sh
mulle-functions.sh
mulle-logging.sh
mulle-options.sh
mulle-snip.sh
mulle-string.sh
)

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


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.txt)
include( CPack)

