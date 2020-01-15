#!/bin/bash
# Copyright 2019, Oracle Corporation and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#  This script leverages the WebLogic image tool to build a WebLogic docker image with patches
#  and without internet access. The version is 12.2.1.3.0 with PS4 and interim patch 2915930 and 30386660
#  
#  Assumptions:
#    build_download.sh should be run first
#    The $WIT_HOME_DIR working directory must have at least 10g of space.
#
#  Expects the following installers to already be installed:
#    JDK Instaler: jdk-8u202-linux-x64.tar.gz to /scratch/artifacts/imagetool
#    WebLogic Installer: fmw_12.2.1.3.0_wls_Disk1_1of1.zip to /scratch/artifacts/imagetool
#    Patch 30386660_12.2.1.3.0 to /scratch/artifacts/imagetool
#    Patch 28186730_13.9.4.0.0 to /scratch/artifacts/imagetool
#    Patch 29135930_12.2.1.3.191004 to /scratch/artifacts/imagetool
#
#  Environment varibale http_proxy and https_proxy are not required
#

# Exit immediately if a command exits with a non-zero status.
set -e

checkCondition()
{
  if [ ! -f "${JDK_WLS_INSTALLER_DIR}/${JDK_INSTALLER_NAME}" ] &&
     [ ! -f "${JDK_WLS_INSTALLER_DIR}/${WLS_INSTALLER_NAME}" ] &&
     [ ! -f "${JDK_WLS_INSTALLER_DIR}/p30386660_122130_Generic.zip" ] &&
     [ ! -f "${JDK_WLS_INSTALLER_DIR}/p28186730_139400_Generic.zip" ] &&
     [ ! -f "${JDK_WLS_INSTALLER_DIR}/p29135930_12213191004_Generic.zip" ]; then
    echo @@
    echo "@@ JDK or WLS installer or requiresd Patches is not installed. Please install them to ${JDK_WLS_INSTALLER_DIR} first! "
    echo @@

    exit 0
  fi

  if [ ! -d ${WIT_HOME_DIR} ] ; then
    echo @@
    echo "@@ imagetool is not installed. Please run build_downlosd.sh to install it! "
    echo @@

    exit 0
  fi
}

cleanup()
{
  echo @@
  echo "@@ Cleanup WIT cache Entry and old WLS docker image"
  echo @@

  # Clean WIT cache
  ${WIT_HOME_DIR}/bin/imagetool cache deleteEntry --key wls_12.2.1.3.0
  ${WIT_HOME_DIR}/bin/imagetool cache deleteEntry --key jdk_8u202
  ${WIT_HOME_DIR}/bin/imagetool cache deleteEntry --key 28186730_opatch
  ${WIT_HOME_DIR}/bin/imagetool cache deleteEntry --key 29135930_12.2.1.3.191004
  ${WIT_HOME_DIR}/bin/imagetool cache deleteEntry --key 30386660_12.2.1.3.0
  ${WIT_HOME_DIR}/bin/imagetool cache listItems

  if [ -d ${WLSIMG_CACHEDIR} ] ; then
    echo @@
    echo "@@ rm -rf ${WLSIMG_CACHEDIR}"
    rm -rf ${WLSIMG_CACHEDIR}
  fi

  if [ -d ${WLSIMG_BLDDIR} ] ; then
    echo @@
    echo "@@ rm -rf ${WLSIMG_BLDDIR}"
    rm -rf ${WLSIMG_BLDDIR}
  fi

  if [ ! -z $(docker images -q ${WLS_IMAGE_TAG}) ]; then
    docker rmi ${WLS_IMAGE_TAG}
    rm -rf ~/wlsimgbuilder_temp*
  fi
}

prepare()
{
  if [ ! -d ${WLSIMG_CACHEDIR} ] ; then
    echo @@
    echo "@@ mkdir ${WLSIMG_CACHEDIR}"
    mkdir -p ${WLSIMG_CACHEDIR}
  fi

  if [ ! -d ${WLSIMG_BLDDIR} ] ; then
    echo @@
    echo "@@ mkdir ${WLSIMG_BLDDIR}"
    mkdir -p ${WLSIMG_BLDDIR}
  fi
}

setupCache()
{
  add_jdk_installer="${WIT_HOME_DIR}/bin/imagetool cache addInstaller --type jdk --version ${JDK_INSTALLER_VERSION} --path ${JDK_WLS_INSTALLER_DIR}/${JDK_INSTALLER_NAME}"
  add_wls_installer="${WIT_HOME_DIR}/bin/imagetool cache addInstaller --type wls --version ${WLS_IMAGE_VERSION} --path ${JDK_WLS_INSTALLER_DIR}/${WLS_INSTALLER_NAME}"
  add_patch_30386660="${WIT_HOME_DIR}/bin/imagetool cache addPatch --patchId 30386660_12.2.1.3.0 --path ${JDK_WLS_INSTALLER_DIR}/p30386660_122130_Generic.zip"
  add_patch_28186730="${WIT_HOME_DIR}/bin/imagetool cache addPatch --patchId 28186730_13.9.4.0.0 --path ${JDK_WLS_INSTALLER_DIR}/p28186730_139400_Generic.zip"
  add_patch_28186730_dep="${WIT_HOME_DIR}/bin/imagetool cache addPatch --patchId 29135930_12.2.1.3.191004 --path ${JDK_WLS_INSTALLER_DIR}/p29135930_12213191004_Generic.zip"

  ${WIT_HOME_DIR}/bin/imagetool cache listItems
  echo "@@ Add installers to WIT cache"
  echo "@@ ${add_jdk_installer}"
  echo "@@ ${add_wls_installer}"
  echo "@@ ${add_patch_30386660}"
  echo "@@ ${add_patch_28186730}"
  echo "@@ ${add_patch_28186730_dep}"
  echo "@@ ${WIT_HOME_DIR}/bin/imagetool cache listItems"
  echo @@
  
  # Add installers to WIT cache
  ${add_jdk_installer}
  ${add_wls_installer}
  ${add_patch_30386660}
  ${add_patch_28186730}
  ${add_patch_28186730_dep}
  ${WIT_HOME_DIR}/bin/imagetool cache listItems
}

createImage()
{
  create_wls_image="${WIT_HOME_DIR}/bin/imagetool create --tag ${WLS_IMAGE_TAG} --version ${WLS_IMAGE_VERSION} --patches 29135930_12.2.1.3.191004,30386660_12.2.1.3.0"

  echo "@@ Create WLS Docker image"
  echo "@@ ${create_wls_image}"
  echo @@
  
  ${create_wls_image}

  if [ $? -eq 0 ]; then
    echo @@
    echo "@@ WebLogic docker image: ${WLS_IMAGE_TAG} created successfully!"
    echo @@
  else
    echo @@
    echo "@@ Failed to create WebLogic docker image"
    echo @@
  fi
}

#### Main
WIT_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cd ${WIT_SCRIPT_DIR}

# Set up WIT cache env var
source ${WIT_SCRIPT_DIR}/build_image_init.sh
export WLSIMG_CACHEDIR=${WLSIMG_CACHEDIR}
export WLSIMG_BLDDIR=${WLSIMG_BLDDIR}

echo @@
echo "========I nstallers are located at ${JDK_WLS_INSTALLER_DIR}"
echo @@

checkCondition
cleanup
prepare
setupCache
createImage
