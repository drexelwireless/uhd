#
# Copyright 2010-2011 Ettus Research LLC
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

IF(NOT DEFINED INCLUDED_UHD_PYTHON_CMAKE)
SET(INCLUDED_UHD_PYTHON_CMAKE TRUE)

########################################################################
# Setup Python
########################################################################
MESSAGE(STATUS "")
MESSAGE(STATUS "Configuring the python interpreter...")
# PYTHON_EXECUTABLE overrides interpreter discovery. FindPython3 validates the
# selected interpreter against the minimum version, and the build invokes it
# through PYTHON_EXECUTABLE.
IF(PYTHON_EXECUTABLE)
    SET(Python3_EXECUTABLE ${PYTHON_EXECUTABLE})
ENDIF(PYTHON_EXECUTABLE)
FIND_PACKAGE(Python3 3.8 REQUIRED COMPONENTS Interpreter)
SET(PYTHON_EXECUTABLE ${Python3_EXECUTABLE} CACHE FILEPATH "python interpreter" FORCE)

MESSAGE(STATUS "Python interpreter: ${PYTHON_EXECUTABLE} (${Python3_VERSION})")
MESSAGE(STATUS "Override with: -DPYTHON_EXECUTABLE=<path-to-python>")

# PYTHON_CHECK_MODULE_VERSION(desc mod min have) sets have to TRUE when the
# selected interpreter can import mod and mod.__version__ is at least min.
# CMake compares the versions component by component as numbers.
MACRO(PYTHON_CHECK_MODULE_VERSION desc mod min have)
    MESSAGE(STATUS "")
    MESSAGE(STATUS "Python checking for ${desc}")
    EXECUTE_PROCESS(
        COMMAND ${PYTHON_EXECUTABLE} -c "import ${mod}; print(${mod}.__version__)"
        RESULT_VARIABLE _uhd_python_module_result
        OUTPUT_VARIABLE _uhd_python_module_version
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    IF(NOT _uhd_python_module_result EQUAL 0)
        MESSAGE(STATUS "Python checking for ${desc} - \"import ${mod}\" failed or ${mod}.__version__ is missing")
        SET(${have} FALSE)
    ELSEIF(_uhd_python_module_version VERSION_LESS ${min})
        MESSAGE(STATUS "Python checking for ${desc} - found ${_uhd_python_module_version}, but ${min} or greater is required")
        SET(${have} FALSE)
    ELSE()
        MESSAGE(STATUS "Python checking for ${desc} - found ${_uhd_python_module_version}")
        SET(${have} TRUE)
    ENDIF()
ENDMACRO(PYTHON_CHECK_MODULE_VERSION)

ENDIF(NOT DEFINED INCLUDED_UHD_PYTHON_CMAKE)
