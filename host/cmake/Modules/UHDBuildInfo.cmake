#
# Copyright 2015-2016 National Instruments Corp.
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

#
# We need this to be macro because GET_DIRECTORY_PROPERTY works with
# the current directory.
#
MACRO(UHD_LOAD_BUILD_INFO)
    MESSAGE(STATUS "")
    MESSAGE(STATUS "Loading build info.")

    # Build date
    IF(IGNORE_BUILD_DATE)
        SET(UHD_BUILD_DATE "")
    ELSE()
        EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c
            "import time; print(time.strftime('%a, %d %b %Y %H:%M:%S', time.gmtime()))"
            OUTPUT_VARIABLE UHD_BUILD_DATE OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    ENDIF(IGNORE_BUILD_DATE)

    # Compiler name
    IF(MSVC)
        IF(MSVC10)
            SET(UHD_C_COMPILER "MSVC 2010")
            SET(UHD_CXX_COMPILER "MSVC 2010")
        ELSEIF(MSVC11)
            SET(UHD_C_COMPILER "MSVC 2012")
            SET(UHD_CXX_COMPILER "MSVC 2012")
        ELSEIF(MSVC12)
            SET(UHD_C_COMPILER "MSVC 2013")
            SET(UHD_CXX_COMPILER "MSVC 2013")
        ELSEIF(MSVC14)
            SET(UHD_C_COMPILER "MSVC 2015")
            SET(UHD_CXX_COMPILER "MSVC 2015")
        ELSE()
            # Go with the ugly string
            SET(UHD_C_COMPILER "MSVC ${CMAKE_C_COMPILER_VERSION}")
            SET(UHD_CXX_COMPILER "MSVC ${CMAKE_CXX_COMPILER_VERSION}")
        ENDIF(MSVC10)
    ELSE()
        SET(UHD_C_COMPILER "${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
        SET(UHD_CXX_COMPILER "${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
    ENDIF(MSVC)

    # Compiler flags: the directory's compile definitions, the flags for every
    # build type, and then the flags of the active build type. The last part
    # is a generator expression, so lib/CMakeLists.txt writes the flags with
    # FILE(GENERATE) to evaluate it for each configuration.
    IF(MSVC)
        SET(_uhd_define_flag "/D")
    ELSE()
        SET(_uhd_define_flag "-D")
    ENDIF()
    GET_DIRECTORY_PROPERTY(_uhd_defs COMPILE_DEFINITIONS)
    SET(_uhd_def_flags "")
    FOREACH(_uhd_def ${_uhd_defs})
        STRING(APPEND _uhd_def_flags " ${_uhd_define_flag}${_uhd_def}")
    ENDFOREACH()
    FOREACH(_uhd_lang C CXX)
        SET(_uhd_flags "${_uhd_def_flags} ${CMAKE_${_uhd_lang}_FLAGS}")
        STRING(REGEX REPLACE "  +" " " _uhd_flags "${_uhd_flags}")
        STRING(STRIP "${_uhd_flags}" _uhd_flags)
        FOREACH(_uhd_config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
            SET(_uhd_config_flags "${CMAKE_${_uhd_lang}_FLAGS_${_uhd_config}}")
            STRING(STRIP "${_uhd_config_flags}" _uhd_config_flags)
            IF(_uhd_config_flags)
                STRING(REPLACE ">" "$<ANGLE-R>" _uhd_config_flags "${_uhd_config_flags}")
                STRING(REPLACE "," "$<COMMA>" _uhd_config_flags "${_uhd_config_flags}")
                STRING(APPEND _uhd_flags "$<$<CONFIG:${_uhd_config}>: ${_uhd_config_flags}>")
            ENDIF()
        ENDFOREACH()
        # The flags become a C++ string literal.
        STRING(REPLACE "\\" "\\\\" _uhd_flags "${_uhd_flags}")
        STRING(REPLACE "\"" "\\\"" _uhd_flags "${_uhd_flags}")
        SET(UHD_${_uhd_lang}_FLAGS "${_uhd_flags}")
    ENDFOREACH()

    # C++ language standard
    IF(CMAKE_CXX_EXTENSIONS)
        SET(UHD_CXX_STANDARD "gnu++${CMAKE_CXX_STANDARD}")
    ELSE()
        SET(UHD_CXX_STANDARD "c++${CMAKE_CXX_STANDARD}")
    ENDIF()

    # libusb: the version found by pkg-config during configuration
    IF(ENABLE_USB)
        SET(UHD_BUILD_INFO_HAVE_LIBUSB 1)
        IF(PC_LIBUSB_VERSION)
            SET(UHD_LIBUSB_VERSION "${PC_LIBUSB_VERSION}")
        ELSE()
            SET(UHD_LIBUSB_VERSION "unknown")
        ENDIF()
    ELSE()
        SET(UHD_BUILD_INFO_HAVE_LIBUSB 0)
        SET(UHD_LIBUSB_VERSION "N/A")
    ENDIF()
ENDMACRO(UHD_LOAD_BUILD_INFO)
