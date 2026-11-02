#
# Copyright 2010-2011,2013,2015 Ettus Research LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

########################################################################
# A cache written before component requests existed stores automatic
# results as BOOL entries, so ON in such a cache does not mean that the user
# required the component.
########################################################################
IF(DEFINED CACHE{_uhd_enabled_components} AND NOT DEFINED CACHE{_uhd_component_requests})
    SET(_uhd_legacy_component_cache TRUE)
ELSE()
    SET(_uhd_legacy_component_cache FALSE)
ENDIF()
SET(_uhd_component_requests TRUE CACHE INTERNAL "")
SET(_uhd_enabled_components "" CACHE INTERNAL "" FORCE)
SET(_uhd_disabled_components "" CACHE INTERNAL "" FORCE)

########################################################################
# Register a component into the system
#  - name the component string name
#  - var the global enable variable
#  - enb the default enable setting
#  - deps a list of dependencies
#  - dis the setting when dependencies are not met
#  - req fail if dependencies not met (unless specifically disabled)
#
# The cache variable ${var} holds the request. AUTO enables the component
# when its dependencies are met, ON requires it and fails configuration
# otherwise, and OFF disables it. The default request is OFF when enb is OFF,
# ON when req is ON, and AUTO otherwise.
#
# The macro then sets ${var} to TRUE or FALSE as a normal variable in the
# current directory scope and its parent, so that later code, including
# directories added after the registering one, sees the effective setting
# rather than the request.
########################################################################
MACRO(LIBUHD_REGISTER_COMPONENT name var enb deps dis req)
    MESSAGE(STATUS "")
    MESSAGE(STATUS "Configuring ${name} support...")

    IF(NOT ${enb})
        SET(_uhd_request OFF)
    ELSEIF(${req})
        SET(_uhd_request ON)
    ELSE()
        SET(_uhd_request AUTO)
    ENDIF()
    IF(DEFINED CACHE{${var}})
        STRING(TOUPPER "$CACHE{${var}}" _uhd_value)
        GET_PROPERTY(_uhd_type CACHE ${var} PROPERTY TYPE)
        IF(_uhd_value MATCHES "^(ON|YES|Y|TRUE|1)$")
            IF(_uhd_legacy_component_cache AND _uhd_type STREQUAL "BOOL")
                MESSAGE(STATUS "  Treating ${var}=ON from an earlier cache as AUTO.")
                MESSAGE(STATUS "  Set -D${var}=ON to require ${name} support.")
                SET(_uhd_request AUTO)
            ELSE()
                SET(_uhd_request ON)
            ENDIF()
        ELSEIF(_uhd_value MATCHES "^(OFF|NO|N|FALSE|0)$")
            SET(_uhd_request OFF)
        ELSEIF(_uhd_value STREQUAL "AUTO")
            SET(_uhd_request AUTO)
        ELSE()
            MESSAGE(FATAL_ERROR "${var} must be AUTO, ON, or OFF, not \"$CACHE{${var}}\".")
        ENDIF()
    ENDIF()
    SET(${var} ${_uhd_request} CACHE STRING "Enable ${name} support (AUTO, ON, or OFF)" FORCE)
    SET_PROPERTY(CACHE ${var} PROPERTY STRINGS AUTO ON OFF)
    MESSAGE(STATUS "  Requested: ${_uhd_request}")

    #check the dependencies, recording why each unmet one is unavailable
    SET(_uhd_unmet "")
    FOREACH(dep ${deps})
        MESSAGE(STATUS "  Dependency ${dep} = ${${dep}}")
        IF(NOT ${dep})
            GET_PROPERTY(_uhd_reason GLOBAL PROPERTY UHD_COMPONENT_UNMET_${dep})
            IF(_uhd_reason)
                LIST(APPEND _uhd_unmet "${dep} (${_uhd_reason})")
            ELSE()
                LIST(APPEND _uhd_unmet "${dep}")
            ENDIF()
        ENDIF()
    ENDFOREACH(dep)
    STRING(REPLACE ";" ", " _uhd_unmet "${_uhd_unmet}")

    IF(_uhd_request STREQUAL "OFF")
        SET(_uhd_enabled FALSE)
        SET_PROPERTY(GLOBAL PROPERTY UHD_COMPONENT_UNMET_${var} "set to OFF")
    ELSEIF(_uhd_unmet)
        IF(_uhd_request STREQUAL "ON")
            MESSAGE(FATAL_ERROR
                "${name} support was requested with ${var}=ON, but its dependencies are not met: "
                "${_uhd_unmet}. Install the missing dependencies, or set ${var} to AUTO or OFF.")
        ENDIF()
        SET(_uhd_enabled ${dis})
        SET_PROPERTY(GLOBAL PROPERTY UHD_COMPONENT_UNMET_${var} "unmet: ${_uhd_unmet}")
    ELSE()
        SET(_uhd_enabled TRUE)
    ENDIF()

    #publish the effective setting to this scope and its parent
    SET(${var} ${_uhd_enabled})
    GET_DIRECTORY_PROPERTY(_uhd_parent PARENT_DIRECTORY)
    IF(_uhd_parent)
        SET(${var} ${_uhd_enabled} PARENT_SCOPE)
    ENDIF()

    #append the component into one of the lists
    IF(${var})
        MESSAGE(STATUS "  Enabling ${name} support.")
        LIST(APPEND _uhd_enabled_components ${name})
    ELSE(${var})
        MESSAGE(STATUS "  Disabling ${name} support.")
        LIST(APPEND _uhd_disabled_components ${name})
    ENDIF(${var})
    MESSAGE(STATUS "  Override with -D${var}=AUTO/ON/OFF")

    #make components lists into global variables
    SET(_uhd_enabled_components ${_uhd_enabled_components} CACHE INTERNAL "" FORCE)
    SET(_uhd_disabled_components ${_uhd_disabled_components} CACHE INTERNAL "" FORCE)
ENDMACRO(LIBUHD_REGISTER_COMPONENT)

########################################################################
# Install only if appropriate for package and if component is enabled
########################################################################
FUNCTION(UHD_INSTALL)
    include(CMakeParseArgumentsCopy)
    CMAKE_PARSE_ARGUMENTS(UHD_INSTALL "" "DESTINATION;COMPONENT" "TARGETS;FILES;PROGRAMS" ${ARGN})

    IF(UHD_INSTALL_FILES)
        SET(TO_INSTALL "${UHD_INSTALL_FILES}")
    ELSEIF(UHD_INSTALL_PROGRAMS)
        SET(TO_INSTALL "${UHD_INSTALL_PROGRAMS}")
    ELSEIF(UHD_INSTALL_TARGETS)
        SET(TO_INSTALL "${UHD_INSTALL_TARGETS}")
    ENDIF(UHD_INSTALL_FILES)

    IF(UHD_INSTALL_COMPONENT STREQUAL "headers")
        IF(NOT LIBUHD_PKG AND NOT UHDHOST_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT UHDHOST_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "devel")
        IF(NOT LIBUHD_PKG AND NOT UHDHOST_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT UHDHOST_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "examples")
        IF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "tests")
        IF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "utilities")
        IF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "manual")
        IF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "doxygen")
        IF(NOT LIBUHD_PKG AND NOT UHDHOST_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT UHDHOST_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "manpages")
        IF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "images")
        IF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG AND NOT UHDHOST_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG AND NOT UHDHOST_PKG)
    ELSEIF(UHD_INSTALL_COMPONENT STREQUAL "readme")
        IF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG AND NOT UHDHOST_PKG)
            INSTALL(${ARGN})
        ENDIF(NOT LIBUHD_PKG AND NOT LIBUHDDEV_PKG AND NOT UHDHOST_PKG)
    ENDIF(UHD_INSTALL_COMPONENT STREQUAL "headers")
ENDFUNCTION(UHD_INSTALL)

########################################################################
# Print the registered component summary
########################################################################
FUNCTION(UHD_PRINT_COMPONENT_SUMMARY)
    MESSAGE(STATUS "")
    MESSAGE(STATUS "######################################################")
    MESSAGE(STATUS "# UHD enabled components                              ")
    MESSAGE(STATUS "######################################################")
    FOREACH(comp ${_uhd_enabled_components})
        MESSAGE(STATUS "  * ${comp}")
    ENDFOREACH(comp)

    MESSAGE(STATUS "")
    MESSAGE(STATUS "######################################################")
    MESSAGE(STATUS "# UHD disabled components                             ")
    MESSAGE(STATUS "######################################################")
    FOREACH(comp ${_uhd_disabled_components})
        MESSAGE(STATUS "  * ${comp}")
    ENDFOREACH(comp)

    MESSAGE(STATUS "")
ENDFUNCTION(UHD_PRINT_COMPONENT_SUMMARY)
