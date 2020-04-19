cmake_minimum_required(VERSION 3.0.0 FATAL_ERROR)

include(${CMAKE_CURRENT_LIST_DIR}/QtStaticCMake.cmake)

# Keep location for later use
set(QT_STATIC_SOURCE_DIR ${QT_STATIC_SOURCE_DIR} CACHE STRING "Source directory of QtStaticCMake.cmake" FORCE)
set(QT_STATIC_QT_ROOT ${QT_STATIC_QT_ROOT} CACHE STRING "Qt sdk root folder" FORCE)
set(QT_STATIC_CMAKE_FOUND ON CACHE BOOL "QtStaticCMake have been found" FORCE)
set(QT_STATIC_CMAKE_VERSION "1.0.1" CACHE STRING "QtStaticCMake version" FORCE)
