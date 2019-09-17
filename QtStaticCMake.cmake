cmake_minimum_required(VERSION 3.0)

# ┌──────────────────────────────────────────────────────────────────┐
# │                       ENVIRONMENT                                │
# └──────────────────────────────────────────────────────────────────┘

# find the Qt root directory
if(NOT Qt5Core_DIR)
    find_package(Qt5Core REQUIRED)
endif()
get_filename_component(QT_STATIC_QT_ROOT "${Qt5Core_DIR}/../../.." ABSOLUTE)
message(STATUS "Found Qt SDK Root: ${QT_STATIC_QT_ROOT}")

set(QT_STATIC_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})

# Indicate that we have found the root sdk
set(QT_STATIC_CMAKE_FOUND ON CACHE BOOL "QtStaticCMake have been found" FORCE)
set(QT_STATIC_CMAKE_VERSION "1.0.1" CACHE STRING "QtStaticCMake version" FORCE)

# ┌──────────────────────────────────────────────────────────────────┐
# │                    GENERATE QML PLUGIN                           │
# └──────────────────────────────────────────────────────────────────┘

# We need to parse some arguments
include(CMakeParseArguments)

# Usage: 
# qt_generate_qml_plugin_import(YourApp
#   QML_DIR "/path/to/qtsdk"
#   QML_SRC "/path/to/yourApp/qml"
#   OUTPUT "YourApp_qml_plugin_import.cpp"
#   OUTPUT_DIR "/path/to/generate"
#   VERBOSE
#)
macro(qt_generate_qml_plugin_import TARGET)

    set(QT_STATIC_OPTIONS VERBOSE )
    set(QT_STATIC_ONE_VALUE_ARG QML_DIR
        QML_SRC
        OUTPUT
        OUTPUT_DIR
        )
    set(QT_STATIC_MULTI_VALUE_ARG )

     # parse the macro arguments
    cmake_parse_arguments(ARGSTATIC "${QT_STATIC_OPTIONS}" "${QT_STATIC_ONE_VALUE_ARG}" "${QT_STATIC_MULTI_VALUE_ARG}" ${ARGN})

    # Copy arg variables to local variables
    set(QT_STATIC_TARGET ${TARGET})
    set(QT_STATIC_QML_DIR ${ARGSTATIC_QML_DIR})
    set(QT_STATIC_QML_SRC ${ARGSTATIC_QML_SRC})
    set(QT_STATIC_OUTPUT ${ARGSTATIC_OUTPUT})
    set(QT_STATIC_OUTPUT_DIR ${ARGSTATIC_OUTPUT_DIR})
    set(QT_STATIC_VERBOSE ${ARGSTATIC_VERBOSE})

    # Default to QtSdk/qml
    if(NOT QT_STATIC_QML_DIR)
        set(QT_STATIC_QML_DIR "${QT_STATIC_QT_ROOT}/qml")
        if(QT_STATIC_VERBOSE)
        message(STATUS "QML_DIR not specified, default to ${QT_STATIC_QML_DIR}")
        endif()
    endif()

    # Default to ${QT_STATIC_TARGET}_qml_plugin_import.cpp
    if(NOT QT_STATIC_OUTPUT)
        set(QT_STATIC_OUTPUT ${QT_STATIC_TARGET}_qml_plugin_import.cpp)
        if(QT_STATIC_VERBOSE)
        message(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT}")
        endif()
    endif()

    # Default to project build directory
    if(NOT QT_STATIC_OUTPUT_DIR)
        set(QT_STATIC_OUTPUT_DIR ${PROJECT_BINARY_DIR})
        if(QT_STATIC_VERBOSE)
        message(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT_DIR}")
        endif()
    endif()

    # Print config
    if(QT_STATIC_VERBOSE)
        message(STATUS "------ QtStaticCMake Qml Generate Configuration ------")
        message(STATUS "TARGET      : ${QT_STATIC_TARGET}")
        message(STATUS "QML_DIR     : ${QT_STATIC_QML_DIR}")
        message(STATUS "QML_SRC     : ${QT_STATIC_QML_SRC}")
        message(STATUS "OUTPUT      : ${QT_STATIC_OUTPUT}")
        message(STATUS "OUTPUT_DIR  : ${QT_STATIC_OUTPUT_DIR}")
        message(STATUS "------ QtStaticCMake Qml Generate End Configuration ------")
    endif()

    if(QT_STATIC_QML_SRC)
        # Debug
        if(QT_STATIC_VERBOSE)
        message(STATUS "Get Qml Plugin dependencies for ${QT_STATIC_TARGET}. qmlimportscanner path is ${QT_STATIC_QT_ROOT}/bin/qmlimportscanner. RootPath is ${QT_STATIC_QML_SRC} and importPath is ${QT_STATIC_QML_DIR}.")
        endif()

        # Get Qml Plugin dependencies
        execute_process(
            COMMAND ${QT_STATIC_QT_ROOT}/bin/qmlimportscanner -rootPath ${QT_STATIC_QML_SRC} -importPath ${QT_STATIC_QML_DIR} 
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            OUTPUT_VARIABLE QT_STATIC_QML_DEPENDENCIES_JSON
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Dump Json File for debug
        #message(STATUS ${QT_STATIC_QML_DEPENDENCIES_JSON})

        # match all classname: (QtPluginStuff)
        string(REGEX MATCHALL "\"classname\"\\: \"([a-zA-Z0-9]*)\""
           QT_STATIC_QML_DEPENDENCIES_JSON_MATCH ${QT_STATIC_QML_DEPENDENCIES_JSON})

        # Show regex match for debug
        #message(STATUS "match : ${QT_STATIC_QML_DEPENDENCIES_JSON_MATCH}")

        # Loop over each match to extract plugin name
        foreach(MATCH ${QT_STATIC_QML_DEPENDENCIES_JSON_MATCH})
            # Debug output
            #message(STATUS "MATCH : ${MATCH}")
            # Extract plugin name
            string(REGEX MATCH "\"classname\"\\: \"([a-zA-Z0-9]*)\"" MATCH_OUT ${MATCH})
            # Debug output
            #message(STATUS "CMAKE_MATCH_1 : ${CMAKE_MATCH_1}")
            # Check plugin isn't present in the list QT_STATIC_QML_DEPENDENCIES_PLUGINS
            list(FIND QT_STATIC_QML_DEPENDENCIES_PLUGINS ${CMAKE_MATCH_1} _PLUGIN_INDEX)
            if(_PLUGIN_INDEX EQUAL -1)
                list(APPEND QT_STATIC_QML_DEPENDENCIES_PLUGINS ${CMAKE_MATCH_1})
            endif()
        endforeach()

        # Print dependencies
        if(QT_STATIC_VERBOSE)
        message(STATUS "${QT_STATIC_TARGET} qml plugin dependencies:")
        foreach(PLUGIN ${QT_STATIC_QML_DEPENDENCIES_PLUGINS})
            message(STATUS "${PLUGIN}")
        endforeach()
        endif()

        if(QT_STATIC_VERBOSE)
        message(STATUS "Generate ${QT_STATIC_OUTPUT} in ${QT_STATIC_OUTPUT_DIR}")
        endif()

        # Build file path
        set(QT_STATIC_QML_PLUGIN_SRC_FILE "${QT_STATIC_OUTPUT_DIR}/${QT_STATIC_OUTPUT}")

        # Write file header
        file(WRITE ${QT_STATIC_QML_PLUGIN_SRC_FILE} "// File Generated via CMake script during build time.\n"
            "// The purpose of this file is to force the static load of qml plugin during static build\n"
            "// Please rerun CMake to update this file.\n"
            "// File will be overwrite at each CMake run.\n"
            "\n#include <QtPlugin>\n\n")

        # Write Q_IMPORT_PLUGIN for each plugin
        foreach(PLUGIN ${QT_STATIC_QML_DEPENDENCIES_PLUGINS})
            file(APPEND ${QT_STATIC_QML_PLUGIN_SRC_FILE} "Q_IMPORT_PLUGIN(${PLUGIN});\n")
        endforeach()

        # Add the file to the target sources
        if(QT_STATIC_VERBOSE)
        message(STATUS "Add ${QT_STATIC_QML_PLUGIN_SRC_FILE} to ${QT_STATIC_TARGET} sources")
        endif()
        target_sources(${QT_STATIC_TARGET} PRIVATE ${QT_STATIC_QML_PLUGIN_SRC_FILE})
    else()
        message(WARNING "QT_STATIC_QML_SRC not specified. Can't generate Q_IMPORT_PLUGIN for qml plugin")
    endif()
endmacro()

# ┌──────────────────────────────────────────────────────────────────┐
# │                     GENERATE QT PLUGIN                           │
# └──────────────────────────────────────────────────────────────────┘

# Usage: 
# qt_generate_plugin_import(YourApp
#   OUTPUT "YourApp_plugin_import.cpp"
#   OUTPUT_DIR "/path/to/generate"
#   VERBOSE
#)
macro(qt_generate_plugin_import TARGET)

    set(QT_STATIC_OPTIONS VERBOSE )
    set(QT_STATIC_ONE_VALUE_ARG OUTPUT
        OUTPUT_DIR
        )

    set(QT_STATIC_MULTI_VALUE_ARG)

     # parse the macro arguments
    cmake_parse_arguments(ARGSTATIC "${QT_STATIC_OPTIONS}" "${QT_STATIC_ONE_VALUE_ARG}" "${QT_STATIC_MULTI_VALUE_ARG}" ${ARGN})

    # Copy arg variables to local variables
    set(QT_STATIC_TARGET ${TARGET})
    set(QT_STATIC_OUTPUT ${ARGSTATIC_OUTPUT})
    set(QT_STATIC_OUTPUT_DIR ${ARGSTATIC_OUTPUT_DIR})
    set(QT_STATIC_VERBOSE ${ARGSTATIC_VERBOSE})

    # Default to ${QT_STATIC_TARGET}_qml_plugin_import.cpp
    if(NOT QT_STATIC_OUTPUT)
        set(QT_STATIC_OUTPUT ${QT_STATIC_TARGET}_plugin_import.cpp)
        if(QT_STATIC_VERBOSE)
            message(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT}")
        endif()
    endif()

    # Default to project build directory
    if(NOT QT_STATIC_OUTPUT_DIR)
        set(QT_STATIC_OUTPUT_DIR ${PROJECT_BINARY_DIR})
        if(QT_STATIC_VERBOSE)
            message(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT_DIR}")
        endif()
    endif()

    # Print config
    if(QT_STATIC_VERBOSE)
        message(STATUS "------ QtStaticCMake Plugin Generate Configuration ------")
        message(STATUS "TARGET   : ${QT_STATIC_TARGET}")
        message(STATUS "OUTPUT      : ${QT_STATIC_OUTPUT}")
        message(STATUS "OUTPUT_DIR  : ${QT_STATIC_OUTPUT_DIR}")
        message(STATUS "------ QtStaticCMake Plugin Generate End Configuration ------")
    endif()

    if(QT_STATIC_VERBOSE)
        message(STATUS "Generate ${QT_STATIC_OUTPUT} in ${QT_STATIC_OUTPUT_DIR}")
    endif()

    set(QT_STATIC_PLUGIN_SRC_FILE "${QT_STATIC_OUTPUT_DIR}/${QT_STATIC_OUTPUT}")

    # Write the file header
    file(WRITE ${QT_STATIC_PLUGIN_SRC_FILE} "// File Generated via CMake script during build time.\n"
        "// The purpose of this file is to force the static load of qml plugin during static build\n"
        "// Please rerun CMake to update this file.\n"
        "// File will be overwrite at each CMake run.\n"
        "\n#include <QtPlugin>\n\n")

    # Get all available Qt5 module
    file(GLOB QT_STATIC_AVAILABLES_QT_DIRECTORIES
        LIST_DIRECTORIES true 
        RELATIVE ${QT_STATIC_QT_ROOT}/lib/cmake
        ${QT_STATIC_QT_ROOT}/lib/cmake/Qt5*)
    foreach(DIR ${QT_STATIC_AVAILABLES_QT_DIRECTORIES})
        set(DIR_PRESENT ${${DIR}_DIR})
        if(DIR_PRESENT)
            set(DIR_PLUGIN_CONTENT ${${DIR}_PLUGINS})
            # Only print if there are some plugin
            if(DIR_PLUGIN_CONTENT)
                # Comment for help dubugging
                file(APPEND ${QT_STATIC_PLUGIN_SRC_FILE} "\n// ${DIR}\n")
                # Parse Plugin to append to the list only if unique
                foreach(PLUGIN ${DIR_PLUGIN_CONTENT})
                    # List form is Qt5::NameOfPlugin, we just need NameOfPlugin
                    string(REGEX MATCH ".*\\:\\:(.*)" PLUGIN_MATCH ${PLUGIN})
                    set(PLUGIN_NAME ${CMAKE_MATCH_1})
                    # Should be NameOfPlugin
                    if(PLUGIN_NAME)
                        # Keep track to only write once each plugin
                        list(FIND QT_STATIC_DEPENDENCIES_PLUGINS ${PLUGIN_NAME} _PLUGIN_INDEX)
                        # Only Write/Keep track if the plugin isn't already present
                        if(_PLUGIN_INDEX EQUAL -1)
                            list(APPEND QT_STATIC_DEPENDENCIES_PLUGINS ${PLUGIN_NAME})
                            file(APPEND ${QT_STATIC_PLUGIN_SRC_FILE} "Q_IMPORT_PLUGIN(${PLUGIN_NAME});\n")
                        endif()
                    endif()
                endforeach()
            endif()
        endif()
    endforeach()

    # Print dependencies
    if(QT_STATIC_VERBOSE)
        message(STATUS "${QT_STATIC_TARGET} plugin dependencies:")
        foreach(PLUGIN ${QT_STATIC_DEPENDENCIES_PLUGINS})
            message(STATUS "${PLUGIN}")
        endforeach()
    endif()

    # Add the generated file into source of the application
    if(QT_STATIC_VERBOSE)
        message(STATUS "Add ${QT_STATIC_PLUGIN_SRC_FILE} to ${QT_STATIC_TARGET} sources")
    endif()
    target_sources(${QT_STATIC_TARGET} PRIVATE ${QT_STATIC_PLUGIN_SRC_FILE})

    # Link to the platform library
    if(QT_STATIC_VERBOSE)
        message(STATUS "Add -u _qt_registerPlatformPlugin linker flag to ${QT_IOS_TARGET} in order to force load qios library")
    endif()
    target_link_libraries(${QT_STATIC_TARGET} "-u _qt_registerPlatformPlugin")

endmacro()
