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

MACRO(PYTHON_CHECK_MODULE desc mod cmd have)
    MESSAGE(STATUS "")
    MESSAGE(STATUS "Python checking for ${desc}")
    EXECUTE_PROCESS(
        COMMAND ${PYTHON_EXECUTABLE} -c "
#########################################
try: import ${mod}
except: exit(1)
try: assert ${cmd}
except: exit(2)
exit(0)
#########################################"
        RESULT_VARIABLE ${have}
    )
    IF(${have} EQUAL 0)
        MESSAGE(STATUS "Python checking for ${desc} - found")
        SET(${have} TRUE)
    ELSEIF(${have} EQUAL 1)
        MESSAGE(STATUS "Python checking for ${desc} - \"import ${mod}\" failed")
        SET(${have} FALSE)
    ELSEIF(${have} EQUAL 2)
        MESSAGE(STATUS "Python checking for ${desc} - \"assert ${cmd}\" failed")
        SET(${have} FALSE)
    ELSE()
        MESSAGE(STATUS "Python checking for ${desc} - unknown error")
        SET(${have} FALSE)
    ENDIF()
ENDMACRO(PYTHON_CHECK_MODULE)

ENDIF(NOT DEFINED INCLUDED_UHD_PYTHON_CMAKE)
