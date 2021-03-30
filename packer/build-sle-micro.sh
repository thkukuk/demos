#!/bin/bash

PACKER=${PACKER:-"./packer"}

TEMPLATE=${1:-"sle-micro.json"}
TMPDIR=$(mktemp -d tmp.XXXXXXXXXX)

wget https://download.suse.de/install/SLE-Micro-5.0-GM/SHA256SUMS -O "${TMPDIR}/checksum.sha256.tmp"

grep SUSE-MicroOS-5.0-DVD-x86_64-GM-Media.iso "${TMPDIR}/checksum.sha256.tmp" >  "${TMPDIR}/checksum.sha256"

VERSION=5.0
ISO_CHECKSUM=$(cut -d" " -f1 "${TMPDIR}"/checksum.sha256)

# Cleanup old builds
rm -rf builds/qemu/SLE-Micro-${VERSION}

${PACKER} build -var version="${VERSION}" -var iso_checksum="${ISO_CHECKSUM}" "${TEMPLATE}"

mkdir -p images
mv "builds/qemu/SLE-Micro-${VERSION}/SLE-Micro-${VERSION}" "images/SLE-Micro-${VERSION}.qcow2"
pushd images > /dev/null || exit
sha256sum "SLE-Micro-${VERSION}.qcow2" > "SLE-Micro-${VERSION}.qcow2.sha256"
popd > /dev/null || exit

rm -rf "${TMPDIR}"
