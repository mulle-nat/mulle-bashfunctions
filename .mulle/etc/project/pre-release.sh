# -- Pre Release --
#

pre_release()
{
   # get rid of these of later debian build
   exekutor rm -f CPackConfig.cmake CMakeCache.txt CPackSourceConfig.cmake cmake_install.cmake
   exekutor rm -rf CMakeFiles build

   # rebuild combined files
   exekutor cmake .
}

