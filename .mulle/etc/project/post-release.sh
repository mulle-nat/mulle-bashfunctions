# -- Post Release --
# Push stuff into debian repository
#

post_release()
{
   # get rid of these from earlier combined files build
   exekutor rm -f CPackConfig.cmake CMakeCache.txt CPackSourceConfig.cmake cmake_install.cmake
   exekutor rm -rf CMakeFiles build

   rexekutor mulle-project-debian "$@"
}

