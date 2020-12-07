cmake_minimum_required (VERSION 3.13)

# use C, because otherwise a CXX compiler is required
project( mulle-bashfunctions C)



execute_process( COMMAND ./mulle-bashfunctions-env version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_BASHFUNCTIONS_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_BASHFUNCTIONS_VERSION is ${MULLE_BASHFUNCTIONS_VERSION} according to mulle-bashfunctions-env")


set( PROJECT_VERSION "${MULLE_BASHFUNCTIONS_VERSION}")


set( SCRIPTS
mulle-bashfunctions-env
)


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
)

set( MULLE_SDE_EXTENSION_DIRS
   "src/mulle-nat/file.sh"
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

