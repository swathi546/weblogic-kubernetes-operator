#!/bin/bash
# Copyright 2019, Oracle Corporation and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# This script sets up the image tool and the image tool cache for use
# by the scripts that build the base image.
# It also sets up env vars that are used by these scripts.
#
# It's called from 'build_download.sh' and 'build_image_base.sh'
#

# Exit immediately if a command exits with a non-zero status.
set -e  

# Get the absolute path of this file's folder
WIT_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cd ${WIT_SCRIPT_DIR}

# vars for downloading WIT
IMAGE_TOOL_VERSION=${IMAGE_TOOL_VERSION}
WIT_INSTALL_DIR="/scratch/`whoami`/imagetool_dir"
WIT_HOME_DIR="${WIT_INSTALL_DIR}/imagetool"
ZIP_FILE=imagetool.zip

# vars for creating a WebLogic docker image
JDK_WLS_INSTALLER_DIR="/scratch/artifacts/imagetool"
JDK_INSTALLER_NAME="jdk-8u202-linux-x64.tar.gz"
JDK_INSTALLER_VERSION="8u202"
WLS_INSTALLER_NAME="fmw_12.2.1.3.0_wls_Disk1_1of1.zip"
WLS_IMAGE_VERSION="12.2.1.3.0"
WLS_IMAGE_NAME=${WEBLOGIC_IMAGE_NAME:-imagetool/build/weblogic}
WLS_IMAGE_TAG=$WLS_IMAGE_NAME:$WLS_IMAGE_VERSION
DEFAULT_WLSIMG_CACHEDIR="/scratch/`whoami`/imagetool_lib/wit_cachedir"
WLSIMG_CACHEDIR=${WLSIMG_CACHEDIR:-$DEFAULT_WLSIMG_CACHEDIR}
DEFAULT_WLSIMG_BLDDIR="/scratch/`whoami`/imagetool_lib/wit_blddir"
WLSIMG_BLDDIR=${WLSIMG_BLDDIR:-$DEFAULT_WLSIMG_BLDDIR}