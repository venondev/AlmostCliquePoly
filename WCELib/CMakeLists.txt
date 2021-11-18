project(WCELib)

cmake_minimum_required(VERSION 2.8.12)
set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

# !!!! IMPORTANT !!!!!
# Change this to your installation path of CxxWrap
# !!!!!!!!!!!!!!!!!!!!
set(CMAKE_PREFIX_PATH /home/lm/.julia/artifacts/16e1de4679fb8520a8af4e6831c7c8e9893d18b4)

find_package(JlCxx REQUIRED)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")
add_subdirectory(extlib/tlx)

include_directories(
        lib
        lib/CostsParser
        lib/GraphParser
        extlib/tlx
)

set(EXTLIBS tlx)
set(LIBS ${EXTLIBS})

add_library(wce SHARED library.cpp
        lib/costsgraph.cpp lib/costsgraph.h
        lib/graphexception.cpp lib/graphexception.h
        lib/vertexlists.cpp lib/vertexlists.h
        lib/vertexlistsexception.cpp lib/vertexlistsexception.h
        lib/graphset.cpp lib/graphset.h
        lib/GraphParser/edgefileparser.cpp lib/GraphParser/edgefileparser.h
        lib/GraphParser/matrixparser.cpp lib/GraphParser/matrixparser.h
        lib/CostsParser/blastparser.cpp lib/CostsParser/blastparser.h
        lib/probleminstanceexception.cpp lib/probleminstanceexception.h
        lib/edgereduction.h lib/edgereduction.cpp
        lib/weightedprobleminstance.cpp lib/weightedprobleminstance.h
        lib/searchtreeweighted.h lib/searchtreeweighted.cpp
        )

target_link_libraries(wce JlCxx::cxxwrap_julia)
target_link_libraries(wce tlx)

install(TARGETS
        wce
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION lib)
