cmake_minimum_required(VERSION 3.23)
project(cpp_server LANGUAGES CXX)

if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Boost 1.71 REQUIRED CONFIG COMPONENTS system)

add_executable(cpp_server src/server.cpp)

target_link_libraries(cpp_server
    PRIVATE
    Boost::system
)

target_compile_features(cpp_server PRIVATE cxx_std_23)
