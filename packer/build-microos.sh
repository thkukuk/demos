#!/bin/bash

PACKER=${PACKER:-"./packer"}

TEMPLATE=${1:-"microos.json"}
TMPDIR=$(mktemp -d tmp.XXXXXXXXXX)

wget https://download.opensuse.org/tumbleweed/iso/openSUSE-MicroOS-DVD-x86_64-Current.iso.sha256 -O "${TMPDIR}/checksum.sha256"


VERSION=$(sed -e 's|.*-Snapshot\([0-9]*\)-Media.*|\1|g' "${TMPDIR}"/checksum.sha256)
ISO_CHECKSUM=$(cut -d" " -f1 "${TMPDIR}"/checksum.sha256)

# Cleanup old builds
rm -rf builds/qemu/MicroOS-${VERSION}

${PACKER} build -var version="${VERSION}" -var iso_checksum="${ISO_CHECKSUM}" "${TEMPLATE}"

mkdir -p images
mv "builds/qemu/MicroOS-${VERSION}/MicroOS-${VERSION}" "images/MicroOS-${VERSION}.qcow2"
pushd images > /dev/null || exit
sha256sum "MicroOS-${VERSION}.qcow2" > "MicroOS-${VERSION}.qcow2.sha256"
popd > /dev/null || exit

rm -rf "${TMPDIR}"
