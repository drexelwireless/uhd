//
// Copyright 2015 National Instruments Corp.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#include <config.h>

#include <uhd/build_info.hpp>
#include "build_info_flags.hpp"

#include <boost/format.hpp>
#include <boost/version.hpp>
#include <boost/algorithm/string.hpp>

#if @UHD_BUILD_INFO_HAVE_LIBUSB@
#include <libusb.h>
#endif

namespace uhd { namespace build_info {

    const std::string boost_version() {
        return boost::algorithm::replace_all_copy(
            std::string(BOOST_LIB_VERSION), "_", "."
        );
    }

    const std::string build_date() {
        return "@UHD_BUILD_DATE@";
    }

    const std::string c_compiler() {
        return "@UHD_C_COMPILER@";
    }

    const std::string cxx_compiler() {
        return "@UHD_CXX_COMPILER@";
    }

    const std::string c_flags() {
        return UHD_BUILD_INFO_C_FLAGS;
    }

    const std::string cxx_flags() {
        return UHD_BUILD_INFO_CXX_FLAGS;
    }

    const std::string cxx_standard() {
        return "@UHD_CXX_STANDARD@";
    }

    const std::string enabled_components() {
        return boost::algorithm::replace_all_copy(
            std::string("@_uhd_enabled_components@"),
            std::string(";"), std::string(", ")
        );
    }

    const std::string install_prefix() {
        return "@CMAKE_INSTALL_PREFIX@";
    }

    const std::string libusb_version() {
        return "@UHD_LIBUSB_VERSION@";
    }

    const std::string libusb_runtime_version() {
    #if @UHD_BUILD_INFO_HAVE_LIBUSB@
        const struct libusb_version *version = libusb_get_version();
        return str(boost::format("%d.%d.%d")
                      % version->major % version->minor % version->micro);
    #else
        return "N/A";
    #endif
    }
}}
