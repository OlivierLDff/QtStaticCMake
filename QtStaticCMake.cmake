CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

# ┌──────────────────────────────────────────────────────────────────┐
# │                       ENVIRONMENT                                │
# └──────────────────────────────────────────────────────────────────┘

# find the Qt root directory
IF(NOT Qt5Core_DIR)
    find_package(Qt5Core REQUIRED)
ENDIF(NOT Qt5Core_DIR)
GET_FILENAME_COMPONENT(QT_STATIC_QT_ROOT "${Qt5Core_DIR}/../../.." ABSOLUTE)
MESSAGE(STATUS "Found Qt SDK Root: ${QT_STATIC_QT_ROOT}")

SET(QT_STATIC_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})

# Indicate that we have found the root sdk
SET(QT_STATIC_CMAKE_FOUND ON CACHE BOOL "QtStaticCMake have been found" FORCE)
SET(QT_STATIC_CMAKE_VERSION "1.0.1" CACHE STRING "QtStaticCMake version" FORCE)

# ┌──────────────────────────────────────────────────────────────────┐
# │                    GENERATE QML PLUGIN                           │
# └──────────────────────────────────────────────────────────────────┘

# We need to parse some arguments
INCLUDE(CMakeParseArguments)

# Usage: 
# qt_generate_qml_plugin_import(YourApp
#   QML_DIR "/path/to/qtsdk"
#   QML_SRC "/path/to/yourApp/qml"
#   OUTPUT "YourApp_qml_plugin_import.cpp"
#   OUTPUT_DIR "/path/to/generate"
#   VERBOSE
#)
MACRO(qt_generate_qml_plugin_import TARGET)

    SET(QT_STATIC_OPTIONS VERBOSE )
    SET(QT_STATIC_ONE_VALUE_ARG QML_DIR
        QML_SRC
        OUTPUT
        OUTPUT_DIR
        )
    SET(QT_STATIC_MULTI_VALUE_ARG )

     # parse the macro arguments
    CMAKE_PARSE_ARGUMENTS(ARGSTATIC "${QT_STATIC_OPTIONS}" "${QT_STATIC_ONE_VALUE_ARG}" "${QT_STATIC_MULTI_VALUE_ARG}" ${ARGN})

    # Copy arg variables to local variables
    SET(QT_STATIC_TARGET ${TARGET})
    SET(QT_STATIC_QML_DIR ${ARGSTATIC_QML_DIR})
    SET(QT_STATIC_QML_SRC ${ARGSTATIC_QML_SRC})
    SET(QT_STATIC_OUTPUT ${ARGSTATIC_OUTPUT})
    SET(QT_STATIC_OUTPUT_DIR ${ARGSTATIC_OUTPUT_DIR})
    SET(QT_STATIC_VERBOSE ${ARGSTATIC_VERBOSE})

    # Default to QtSdk/qml
    IF(NOT QT_STATIC_QML_DIR)
        SET(QT_STATIC_QML_DIR "${QT_STATIC_QT_ROOT}/qml")
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "QML_DIR not specified, default to ${QT_STATIC_QML_DIR}")
        ENDIF(QT_STATIC_VERBOSE)
    ENDIF(NOT QT_STATIC_QML_DIR)

    # Default to ${QT_STATIC_TARGET}_qml_plugin_import.cpp
    IF(NOT QT_STATIC_OUTPUT)
        SET(QT_STATIC_OUTPUT ${QT_STATIC_TARGET}_qml_plugin_import.cpp)
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT}")
        ENDIF(QT_STATIC_VERBOSE)
    ENDIF(NOT QT_STATIC_OUTPUT)

    # Default to project build directory
    IF(NOT QT_STATIC_OUTPUT_DIR)
        SET(QT_STATIC_OUTPUT_DIR ${PROJECT_BINARY_DIR})
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT_DIR}")
        ENDIF(QT_STATIC_VERBOSE)
    ENDIF(NOT QT_STATIC_OUTPUT_DIR)

    # Print config
    IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "------ QtStaticCMake Qml Generate Configuration ------")
        MESSAGE(STATUS "TARGET      : ${QT_STATIC_TARGET}")
        MESSAGE(STATUS "QML_DIR     : ${QT_STATIC_QML_DIR}")
        MESSAGE(STATUS "QML_SRC     : ${QT_STATIC_QML_SRC}")
        MESSAGE(STATUS "OUTPUT      : ${QT_STATIC_OUTPUT}")
        MESSAGE(STATUS "OUTPUT_DIR  : ${QT_STATIC_OUTPUT_DIR}")
        MESSAGE(STATUS "------ QtStaticCMake Qml Generate End Configuration ------")
    ENDIF(QT_STATIC_VERBOSE)

    IF(QT_STATIC_QML_SRC)
        # Debug
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "Get Qml Plugin dependencies for ${QT_STATIC_TARGET}. qmlimportscanner path is ${QT_STATIC_QT_ROOT}/bin/qmlimportscanner. RootPath is ${QT_STATIC_QML_SRC} and importPath is ${QT_STATIC_QML_DIR}.")
        ENDIF(QT_STATIC_VERBOSE)

        # Get Qml Plugin dependencies
        EXECUTE_PROCESS(
            COMMAND ${QT_STATIC_QT_ROOT}/bin/qmlimportscanner -rootPath ${QT_STATIC_QML_SRC} -importPath ${QT_STATIC_QML_DIR} 
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            OUTPUT_VARIABLE QT_STATIC_QML_DEPENDENCIES_JSON
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Dump Json File for debug
        #MESSAGE(STATUS ${QT_STATIC_QML_DEPENDENCIES_JSON})

        # match all classname: (QtPluginStuff)
        STRING(REGEX MATCHALL "\"classname\"\\: \"([a-zA-Z0-9]*)\""
           QT_STATIC_QML_DEPENDENCIES_JSON_MATCH ${QT_STATIC_QML_DEPENDENCIES_JSON})

        # Show regex match for debug
        #MESSAGE(STATUS "match : ${QT_STATIC_QML_DEPENDENCIES_JSON_MATCH}")

        # Loop over each match to extract plugin name
        FOREACH(MATCH ${QT_STATIC_QML_DEPENDENCIES_JSON_MATCH})
            # Debug output
            #MESSAGE(STATUS "MATCH : ${MATCH}")
            # Extract plugin name
            STRING(REGEX MATCH "\"classname\"\\: \"([a-zA-Z0-9]*)\"" MATCH_OUT ${MATCH})
            # Debug output
            #MESSAGE(STATUS "CMAKE_MATCH_1 : ${CMAKE_MATCH_1}")
            # Check plugin isn't present in the list QT_STATIC_QML_DEPENDENCIES_PLUGINS
            LIST(FIND QT_STATIC_QML_DEPENDENCIES_PLUGINS ${CMAKE_MATCH_1} _PLUGIN_INDEX)
            IF(_PLUGIN_INDEX EQUAL -1)
                LIST(APPEND QT_STATIC_QML_DEPENDENCIES_PLUGINS ${CMAKE_MATCH_1})
            ENDIF(_PLUGIN_INDEX EQUAL -1)
        ENDFOREACH()

        # Print dependencies
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "${QT_STATIC_TARGET} qml plugin dependencies:")
        FOREACH(PLUGIN ${QT_STATIC_QML_DEPENDENCIES_PLUGINS})
            MESSAGE(STATUS "${PLUGIN}")
        ENDFOREACH()
        ENDIF(QT_STATIC_VERBOSE)

        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "Generate ${QT_STATIC_OUTPUT} in ${QT_STATIC_OUTPUT_DIR}")
        ENDIF(QT_STATIC_VERBOSE)

        # Build file path
        SET(QT_STATIC_QML_PLUGIN_SRC_FILE "${QT_STATIC_OUTPUT_DIR}/${QT_STATIC_OUTPUT}")

        # Write file header
        FILE(WRITE ${QT_STATIC_QML_PLUGIN_SRC_FILE} "// File Generated via CMake script during build time.\n"
            "// The purpose of this file is to force the static load of qml plugin during static build\n"
            "// Please rerun CMake to update this file.\n"
            "// File will be overwrite at each CMake run.\n"
            "\n#include <QtPlugin>\n\n")

        # Write Q_IMPORT_PLUGIN for each plugin
        FOREACH(PLUGIN ${QT_STATIC_QML_DEPENDENCIES_PLUGINS})
            FILE(APPEND ${QT_STATIC_QML_PLUGIN_SRC_FILE} "Q_IMPORT_PLUGIN(${PLUGIN});\n")
        ENDFOREACH()

        # Add the file to the target sources
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "Add ${QT_STATIC_QML_PLUGIN_SRC_FILE} to ${QT_STATIC_TARGET} sources")
        ENDIF(QT_STATIC_VERBOSE)
        target_sources(${QT_STATIC_TARGET} PRIVATE ${QT_STATIC_QML_PLUGIN_SRC_FILE})
    ELSE(QT_STATIC_QML_SRC)
        MESSAGE(WARNING "QT_STATIC_QML_SRC not specified. Can't generate Q_IMPORT_PLUGIN for qml plugin")
    ENDIF(QT_STATIC_QML_SRC)
ENDMACRO(qt_generate_qml_plugin_import TARGET)

# ┌──────────────────────────────────────────────────────────────────┐
# │                     GENERATE QT PLUGIN                           │
# └──────────────────────────────────────────────────────────────────┘

# Usage: 
# qt_generate_qml_plugin_import(YourApp
#   OUTPUT "YourApp_plugin_import.cpp"
#   OUTPUT_DIR "/path/to/generate"
#   VERBOSE
#)
MACRO(qt_generate_plugin_import TARGET)

    SET(QT_STATIC_OPTIONS VERBOSE )
    SET(QT_STATIC_ONE_VALUE_ARG OUTPUT
        OUTPUT_DIR
        )

    SET(QT_STATIC_MULTI_VALUE_ARG)

     # parse the macro arguments
    CMAKE_PARSE_ARGUMENTS(ARGSTATIC "${QT_STATIC_OPTIONS}" "${QT_STATIC_ONE_VALUE_ARG}" "${QT_STATIC_MULTI_VALUE_ARG}" ${ARGN})

    # Copy arg variables to local variables
    SET(QT_STATIC_TARGET ${TARGET})
    SET(QT_STATIC_OUTPUT ${ARGSTATIC_OUTPUT})
    SET(QT_STATIC_OUTPUT_DIR ${ARGSTATIC_OUTPUT_DIR})
    SET(QT_STATIC_VERBOSE ${ARGSTATIC_VERBOSE})

    # Default to ${QT_STATIC_TARGET}_qml_plugin_import.cpp
    IF(NOT QT_STATIC_OUTPUT)
        SET(QT_STATIC_OUTPUT ${QT_STATIC_TARGET}_plugin_import.cpp)
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT}")
        ENDIF(QT_STATIC_VERBOSE)
    ENDIF(NOT QT_STATIC_OUTPUT)

    # Default to project build directory
    IF(NOT QT_STATIC_OUTPUT_DIR)
        SET(QT_STATIC_OUTPUT_DIR ${PROJECT_BINARY_DIR})
        IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "OUTPUT not specified, default to ${QT_STATIC_OUTPUT_DIR}")
        ENDIF(QT_STATIC_VERBOSE)
    ENDIF(NOT QT_STATIC_OUTPUT_DIR)

    # Print config
    IF(QT_STATIC_VERBOSE)
        MESSAGE(STATUS "------ QtStaticCMake Plugin Generate Configuration ------")
        MESSAGE(STATUS "TARGET   : ${QT_STATIC_TARGET}")
        MESSAGE(STATUS "OUTPUT      : ${QT_STATIC_OUTPUT}")
        MESSAGE(STATUS "OUTPUT_DIR  : ${QT_STATIC_OUTPUT_DIR}")
        MESSAGE(STATUS "------ QtStaticCMake Plugin Generate End Configuration ------")
    ENDIF(QT_STATIC_VERBOSE)

    IF(QT_STATIC_VERBOSE)
    MESSAGE(STATUS "Generate ${QT_STATIC_OUTPUT} in ${QT_STATIC_OUTPUT_DIR}")
    ENDIF(QT_STATIC_VERBOSE)

    SET(QT_STATIC_PLUGIN_SRC_FILE "${QT_STATIC_OUTPUT_DIR}/${QT_STATIC_OUTPUT}")

    # Write the file header
    FILE(WRITE ${QT_STATIC_PLUGIN_SRC_FILE} "// File Generated via CMake script during build time.\n"
        "// The purpose of this file is to force the static load of qml plugin during static build\n"
        "// Please rerun CMake to update this file.\n"
        "// File will be overwrite at each CMake run.\n"
        "\n#include <QtPlugin>\n\n")

    # Get all available Qt5 module
    FILE(GLOB QT_STATIC_AVAILABLES_QT_DIRECTORIES
        LIST_DIRECTORIES true 
        RELATIVE ${QT_STATIC_QT_ROOT}/lib/cmake
        ${QT_STATIC_QT_ROOT}/lib/cmake/Qt5*)
    FOREACH(DIR ${QT_STATIC_AVAILABLES_QT_DIRECTORIES})
        SET(DIR_PRESENT ${${DIR}_DIR})
        IF(DIR_PRESENT)
            SET(DIR_PLUGIN_CONTENT ${${DIR}_PLUGINS})
            # Only print if there are some plugin
            IF(DIR_PLUGIN_CONTENT)
                # Comment for help dubugging
                FILE(APPEND ${QT_STATIC_PLUGIN_SRC_FILE} "\n// ${DIR}\n")
                # Parse Plugin to append to the list only if unique
                FOREACH(PLUGIN ${DIR_PLUGIN_CONTENT})
                    # List form is Qt5::NameOfPlugin, we just need NameOfPlugin
                    string(REGEX MATCH ".*\\:\\:(.*)" PLUGIN_MATCH ${PLUGIN})
                    SET(PLUGIN_NAME ${CMAKE_MATCH_1})
                    # Should be NameOfPlugin
                    IF(PLUGIN_NAME)
                        # Keep track to only write once each plugin
                        LIST(FIND QT_STATIC_DEPENDENCIES_PLUGINS ${PLUGIN_NAME} _PLUGIN_INDEX)
                        # Only Write/Keep track if the plugin isn't already present
                        IF(_PLUGIN_INDEX EQUAL -1)
                            LIST(APPEND QT_STATIC_DEPENDENCIES_PLUGINS ${PLUGIN_NAME})
                            FILE(APPEND ${QT_STATIC_PLUGIN_SRC_FILE} "Q_IMPORT_PLUGIN(${PLUGIN_NAME});\n")
                        ENDIF(_PLUGIN_INDEX EQUAL -1)
                    ENDIF(PLUGIN_NAME)
                ENDFOREACH()
            ENDIF(DIR_PLUGIN_CONTENT)
        ENDIF()
    ENDFOREACH()

    # Print dependencies
    IF(QT_STATIC_VERBOSE)
    MESSAGE(STATUS "${QT_STATIC_TARGET} plugin dependencies:")
    FOREACH(PLUGIN ${QT_STATIC_DEPENDENCIES_PLUGINS})
        MESSAGE(STATUS "${PLUGIN}")
    ENDFOREACH()
    ENDIF(QT_STATIC_VERBOSE)

    # Add the generated file into source of the application
    IF(QT_STATIC_VERBOSE)
    MESSAGE(STATUS "Add ${QT_STATIC_PLUGIN_SRC_FILE} to ${QT_STATIC_TARGET} sources")
    ENDIF(QT_STATIC_VERBOSE)
    target_sources(${QT_STATIC_TARGET} PRIVATE ${QT_STATIC_PLUGIN_SRC_FILE})

    # Link to the platform library
    IF(QT_STATIC_VERBOSE)
    MESSAGE(STATUS "Add -u _qt_registerPlatformPlugin linker flag to ${QT_IOS_TARGET} in order to force load qios library")
    ENDIF(QT_STATIC_VERBOSE)
    TARGET_LINK_LIBRARIES(${QT_STATIC_TARGET} "-u _qt_registerPlatformPlugin")

ENDMACRO(qt_generate_plugin_import TARGET)
